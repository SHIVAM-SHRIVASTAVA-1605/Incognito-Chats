const { User } = require('../models');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for file upload
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads/profiles');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (extname && mimetype) {
      return cb(null, true);
    }
    cb(new Error('Only image files are allowed'));
  }
}).single('profilePicture');

// Get user profile
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: ['id', 'displayName', 'bio', 'profilePicture']
    });

    res.json({ user });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Update profile
exports.updateProfile = async (req, res) => {
  try {
    const { displayName, bio } = req.body;
    const user = await User.findByPk(req.user.id);

    if (displayName !== undefined) {
      // Validate display name length
      if (displayName.trim().length < 3) {
        return res.status(400).json({ error: 'Display name must be at least 3 characters' });
      }
      if (displayName.trim().length > 50) {
        return res.status(400).json({ error: 'Display name must be less than 50 characters' });
      }
      
      // Check if display name is already taken by another user
      if (displayName !== user.displayName) {
        const existingUser = await User.findOne({ where: { displayName: displayName.trim() } });
        if (existingUser) {
          return res.status(400).json({ error: 'Display name is already taken' });
        }
      }
      
      user.displayName = displayName.trim();
    }
    if (bio !== undefined) {
      user.bio = bio;
    }

    await user.save();

    res.json({
      user: {
        id: user.id,
        displayName: user.displayName,
        bio: user.bio,
        profilePicture: user.profilePicture
      }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    if (error.name === 'SequelizeUniqueConstraintError') {
      return res.status(400).json({ error: 'Display name is already taken' });
    }
    res.status(500).json({ error: 'Server error' });
  }
};

// Upload profile picture
exports.uploadProfilePicture = (req, res) => {
  upload(req, res, async (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    try {
      const user = await User.findByPk(req.user.id);
      
      // Delete old profile picture if exists
      if (user.profilePicture) {
        const oldPath = path.join(__dirname, '..', user.profilePicture);
        if (fs.existsSync(oldPath)) {
          fs.unlinkSync(oldPath);
        }
      }

      // Update user with new profile picture path
      user.profilePicture = `/uploads/profiles/${req.file.filename}`;
      await user.save();

      res.json({
        user: {
          id: user.id,
          displayName: user.displayName,
          bio: user.bio,
          profilePicture: user.profilePicture
        }
      });
    } catch (error) {
      console.error('Upload profile picture error:', error);
      res.status(500).json({ error: 'Server error' });
    }
  });
};

// Delete profile picture
exports.deleteProfilePicture = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id);

    if (user.profilePicture) {
      const filePath = path.join(__dirname, '..', user.profilePicture);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
      user.profilePicture = null;
      await user.save();
    }

    res.json({
      user: {
        id: user.id,
        displayName: user.displayName,
        bio: user.bio,
        profilePicture: user.profilePicture
      }
    });
  } catch (error) {
    console.error('Delete profile picture error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Search users by display name (for starting conversations)
exports.searchUsers = async (req, res) => {
  try {
    const { query } = req.query;
    
    if (!query || query.length < 2) {
      return res.status(400).json({ error: 'Query must be at least 2 characters' });
    }

    const currentUser = await User.findByPk(req.user.id);

    const users = await User.findAll({
      where: {
        displayName: {
          [require('sequelize').Op.iLike]: `%${query}%`
        }
      },
      attributes: ['id', 'displayName', 'bio', 'profilePicture', 'blockedUsers'],
      limit: 20
    });

    // Filter out current user and users who blocked the current user
    const filteredUsers = users.filter(u => {
      if (u.id === req.user.id) return false;
      // If the searched user has blocked the current user, don't show them
      if (u.blockedUsers && u.blockedUsers.includes(req.user.id)) return false;
      return true;
    });

    // Remove blockedUsers field from response
    const sanitizedUsers = filteredUsers.map(u => ({
      id: u.id,
      displayName: u.displayName,
      bio: u.bio,
      profilePicture: u.profilePicture
    }));

    res.json({ users: sanitizedUsers });
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Block a user
exports.blockUser = async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    if (userId === req.user.id) {
      return res.status(400).json({ error: 'Cannot block yourself' });
    }

    // Check if user exists
    const userToBlock = await User.findByPk(userId);
    if (!userToBlock) {
      return res.status(404).json({ error: 'User not found' });
    }

    const currentUser = await User.findByPk(req.user.id);
    
    // Check if already blocked
    if (currentUser.blockedUsers && currentUser.blockedUsers.includes(userId)) {
      return res.status(400).json({ error: 'User is already blocked' });
    }

    // Add to blocked users
    const blockedUsers = currentUser.blockedUsers || [];
    currentUser.blockedUsers = [...blockedUsers, userId];
    await currentUser.save();

    res.json({ message: 'User blocked successfully' });
  } catch (error) {
    console.error('Block user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Unblock a user
exports.unblockUser = async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    const currentUser = await User.findByPk(req.user.id);
    
    // Check if user is blocked
    if (!currentUser.blockedUsers || !currentUser.blockedUsers.includes(userId)) {
      return res.status(400).json({ error: 'User is not blocked' });
    }

    // Remove from blocked users
    currentUser.blockedUsers = currentUser.blockedUsers.filter(id => id !== userId);
    await currentUser.save();

    res.json({ message: 'User unblocked successfully' });
  } catch (error) {
    console.error('Unblock user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get blocked users list
exports.getBlockedUsers = async (req, res) => {
  try {
    const currentUser = await User.findByPk(req.user.id);
    
    if (!currentUser.blockedUsers || currentUser.blockedUsers.length === 0) {
      return res.json({ blockedUsers: [] });
    }

    const blockedUsers = await User.findAll({
      where: {
        id: currentUser.blockedUsers
      },
      attributes: ['id', 'displayName', 'profilePicture']
    });

    res.json({ blockedUsers });
  } catch (error) {
    console.error('Get blocked users error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Check if user is blocked
exports.isUserBlocked = async (req, res) => {
  try {
    const { userId } = req.params;
    
    const currentUser = await User.findByPk(req.user.id);
    const isBlocked = currentUser.blockedUsers && currentUser.blockedUsers.includes(userId);

    res.json({ isBlocked });
  } catch (error) {
    console.error('Check blocked user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

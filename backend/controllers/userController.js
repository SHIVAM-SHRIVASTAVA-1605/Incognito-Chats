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

    const users = await User.findAll({
      where: {
        displayName: {
          [require('sequelize').Op.iLike]: `%${query}%`
        }
      },
      attributes: ['id', 'displayName', 'bio', 'profilePicture'],
      limit: 20
    });

    // Filter out current user
    const filteredUsers = users.filter(u => u.id !== req.user.id);

    res.json({ users: filteredUsers });
  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

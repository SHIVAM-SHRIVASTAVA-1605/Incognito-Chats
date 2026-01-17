const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/auth');

router.get('/profile', authMiddleware, userController.getProfile);
router.put('/profile', authMiddleware, userController.updateProfile);
router.post('/profile/picture', authMiddleware, userController.uploadProfilePicture);
router.delete('/profile/picture', authMiddleware, userController.deleteProfilePicture);
router.get('/search', authMiddleware, userController.searchUsers);
router.post('/block', authMiddleware, userController.blockUser);
router.post('/unblock', authMiddleware, userController.unblockUser);
router.get('/blocked', authMiddleware, userController.getBlockedUsers);
router.get('/blocked/:userId', authMiddleware, userController.isUserBlocked);

module.exports = router;

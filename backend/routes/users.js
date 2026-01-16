const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/auth');

router.get('/profile', authMiddleware, userController.getProfile);
router.put('/profile', authMiddleware, userController.updateProfile);
router.post('/profile/picture', authMiddleware, userController.uploadProfilePicture);
router.delete('/profile/picture', authMiddleware, userController.deleteProfilePicture);
router.get('/search', authMiddleware, userController.searchUsers);

module.exports = router;

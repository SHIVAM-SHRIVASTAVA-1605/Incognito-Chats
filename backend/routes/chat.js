const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const authMiddleware = require('../middleware/auth');

router.get('/conversations', authMiddleware, chatController.getConversations);
router.post('/conversations', authMiddleware, chatController.getOrCreateConversation);
router.get('/conversations/:conversationId/messages', authMiddleware, chatController.getMessages);
router.delete('/conversations/:conversationId', authMiddleware, chatController.deleteConversation);
router.delete('/messages/:messageId', authMiddleware, chatController.deleteMessage);
router.post('/messages/:messageId/reactions', authMiddleware, chatController.addReaction);
router.delete('/messages/:messageId/reactions', authMiddleware, chatController.removeReaction);

module.exports = router;

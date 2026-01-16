const jwt = require('jsonwebtoken');
const { Message, Conversation, User } = require('../models');
const { Op } = require('sequelize');

class SocketHandler {
  constructor(io) {
    this.io = io;
    this.userSockets = new Map(); // userId -> socketId
  }

  initialize() {
    this.io.on('connection', (socket) => {
      console.log('User connected:', socket.id);

      // Authenticate socket connection
      socket.on('authenticate', async (token) => {
        try {
          const decoded = jwt.verify(token, process.env.JWT_SECRET);
          socket.userId = decoded.userId;
          this.userSockets.set(decoded.userId, socket.id);
          socket.emit('authenticated', { success: true });
          console.log(`User ${decoded.userId} authenticated`);
        } catch (error) {
          socket.emit('authenticated', { success: false, error: 'Invalid token' });
          socket.disconnect();
        }
      });

      // Join conversation room
      socket.on('joinConversation', async (conversationId) => {
        try {
          if (!socket.userId) {
            return socket.emit('error', { message: 'Not authenticated' });
          }

          // Verify user is part of conversation
          const conversation = await Conversation.findOne({
            where: {
              id: conversationId,
              [Op.or]: [
                { participant1Id: socket.userId },
                { participant2Id: socket.userId }
              ]
            }
          });

          if (!conversation) {
            return socket.emit('error', { message: 'Conversation not found' });
          }

          socket.join(conversationId);
          console.log(`User ${socket.userId} joined conversation ${conversationId}`);
        } catch (error) {
          console.error('Join conversation error:', error);
          socket.emit('error', { message: 'Failed to join conversation' });
        }
      });

      // Leave conversation room
      socket.on('leaveConversation', (conversationId) => {
        socket.leave(conversationId);
        console.log(`User ${socket.userId} left conversation ${conversationId}`);
      });

      // Send message
      socket.on('sendMessage', async (data) => {
        try {
          const { conversationId, content } = data;

          if (!socket.userId) {
            return socket.emit('error', { message: 'Not authenticated' });
          }

          if (!content || content.trim().length === 0) {
            return socket.emit('error', { message: 'Message content is required' });
          }

          // Verify user is part of conversation
          const conversation = await Conversation.findOne({
            where: {
              id: conversationId,
              [Op.or]: [
                { participant1Id: socket.userId },
                { participant2Id: socket.userId }
              ]
            }
          });

          if (!conversation) {
            return socket.emit('error', { message: 'Conversation not found' });
          }

          // Create message
          const message = await Message.create({
            conversationId,
            senderId: socket.userId,
            content: content.trim()
          });

          // Update conversation's lastMessageAt
          conversation.lastMessageAt = new Date();
          await conversation.save();

          // Get sender info
          const sender = await User.findByPk(socket.userId, {
            attributes: ['id', 'displayName']
          });

          const messageData = {
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            content: message.content,
            createdAt: message.createdAt,
            expiresAt: message.expiresAt,
            sender: {
              id: sender.id,
              displayName: sender.displayName
            }
          };

          // Emit to all users in the conversation room
          this.io.to(conversationId).emit('newMessage', messageData);
          console.log(`Message sent in conversation ${conversationId}`);
        } catch (error) {
          console.error('Send message error:', error);
          socket.emit('error', { message: 'Failed to send message' });
        }
      });

      // Delete message
      socket.on('deleteMessage', async (data) => {
        try {
          const { messageId, conversationId } = data;

          if (!socket.userId) {
            return socket.emit('error', { message: 'Not authenticated' });
          }

          // Find and verify message
          const message = await Message.findByPk(messageId);
          if (!message) {
            return socket.emit('error', { message: 'Message not found' });
          }

          if (message.senderId !== socket.userId) {
            return socket.emit('error', { message: 'You can only delete your own messages' });
          }

          await message.destroy();

          // Notify all users in the conversation
          this.io.to(conversationId).emit('messageDeleted', { messageId });
          console.log(`Message ${messageId} deleted`);
        } catch (error) {
          console.error('Delete message error:', error);
          socket.emit('error', { message: 'Failed to delete message' });
        }
      });

      // Disconnect
      socket.on('disconnect', () => {
        if (socket.userId) {
          this.userSockets.delete(socket.userId);
        }
        console.log('User disconnected:', socket.id);
      });
    });
  }
}

module.exports = SocketHandler;

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

          // Check if either user has blocked the other
          const otherUserId = conversation.participant1Id === socket.userId ? conversation.participant2Id : conversation.participant1Id;
          const currentUser = await User.findByPk(socket.userId);
          const otherUser = await User.findByPk(otherUserId);
          const isBlocked = (currentUser.blockedUsers && currentUser.blockedUsers.includes(otherUserId)) ||
                            (otherUser.blockedUsers && otherUser.blockedUsers.includes(socket.userId));
          
          if (isBlocked) {
            return socket.emit('error', { message: 'Cannot send message - user blocked' });
          }

          // Calculate expiry time
          const expiryHours = parseFloat(process.env.MESSAGE_EXPIRY_HOURS) || 12;
          const expiresAt = new Date(Date.now() + expiryHours * 60 * 60 * 1000);

          // Create message
          const message = await Message.create({
            conversationId,
            senderId: socket.userId,
            content: content.trim(),
            expiresAt
          });

          // Update conversation's lastMessageAt and lastMessagePreview
          conversation.lastMessageAt = new Date();
          conversation.lastMessagePreview = content.trim().length > 50
            ? content.trim().substring(0, 50) + '...'
            : content.trim();
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
            reactions: message.reactions || {},
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

      // Add reaction
      socket.on('addReaction', async (data) => {
        try {
          const { messageId, emoji, conversationId } = data;

          if (!socket.userId) {
            return socket.emit('error', { message: 'Not authenticated' });
          }

          if (!emoji) {
            return socket.emit('error', { message: 'Emoji is required' });
          }

          // Find message
          const message = await Message.findByPk(messageId);
          if (!message) {
            return socket.emit('error', { message: 'Message not found' });
          }

          // Verify user is part of conversation
          const conversation = await Conversation.findByPk(message.conversationId);
          if (conversation.participant1Id !== socket.userId && conversation.participant2Id !== socket.userId) {
            return socket.emit('error', { message: 'Not authorized' });
          }

          // Update reactions
          const reactions = message.reactions || {};
          if (!reactions[emoji]) {
            reactions[emoji] = [];
          }
          
          // Add user to reaction if not already present
          if (!reactions[emoji].includes(socket.userId)) {
            reactions[emoji].push(socket.userId);
          }

          message.reactions = reactions;
          message.changed('reactions', true); // Mark as changed for Sequelize
          await message.save();

          // Notify all users in the conversation
          this.io.to(conversationId).emit('reactionAdded', {
            messageId,
            reactions: message.reactions
          });
          console.log(`Reaction added to message ${messageId}`);
        } catch (error) {
          console.error('Add reaction error:', error);
          socket.emit('error', { message: 'Failed to add reaction' });
        }
      });

      // Remove reaction
      socket.on('removeReaction', async (data) => {
        try {
          const { messageId, emoji, conversationId } = data;

          if (!socket.userId) {
            return socket.emit('error', { message: 'Not authenticated' });
          }

          if (!emoji) {
            return socket.emit('error', { message: 'Emoji is required' });
          }

          // Find message
          const message = await Message.findByPk(messageId);
          if (!message) {
            return socket.emit('error', { message: 'Message not found' });
          }

          // Verify user is part of conversation
          const conversation = await Conversation.findByPk(message.conversationId);
          if (conversation.participant1Id !== socket.userId && conversation.participant2Id !== socket.userId) {
            return socket.emit('error', { message: 'Not authorized' });
          }

          // Update reactions
          const reactions = message.reactions || {};
          if (reactions[emoji]) {
            reactions[emoji] = reactions[emoji].filter(id => id !== socket.userId);
            
            // Remove emoji key if no users left
            if (reactions[emoji].length === 0) {
              delete reactions[emoji];
            }
          }

          message.reactions = reactions;
          message.changed('reactions', true); // Mark as changed for Sequelize
          await message.save();

          // Notify all users in the conversation
          this.io.to(conversationId).emit('reactionRemoved', {
            messageId,
            reactions: message.reactions
          });
          console.log(`Reaction removed from message ${messageId}`);
        } catch (error) {
          console.error('Remove reaction error:', error);
          socket.emit('error', { message: 'Failed to remove reaction' });
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

const { Conversation, Message, User } = require('../models');
const { Op } = require('sequelize');

// Get all conversations for current user
exports.getConversations = async (req, res) => {
  try {
    const userId = req.user.id;
    const currentUser = await User.findByPk(userId);

    const conversations = await Conversation.findAll({
      where: {
        [Op.or]: [
          { participant1Id: userId },
          { participant2Id: userId }
        ]
      },
      include: [
        {
          model: User,
          as: 'participant1',
          attributes: ['id', 'displayName', 'profilePicture', 'blockedUsers']
        },
        {
          model: User,
          as: 'participant2',
          attributes: ['id', 'displayName', 'profilePicture', 'blockedUsers']
        }
      ],
      order: [['lastMessageAt', 'DESC']]
    });

    // Format response to show the other participant
    const formattedConversations = conversations.map(conv => {
      const otherUser = conv.participant1Id === userId ? conv.participant2 : conv.participant1;
      const isBlocked = (currentUser.blockedUsers && currentUser.blockedUsers.includes(otherUser.id)) ||
                        (otherUser.blockedUsers && otherUser.blockedUsers.includes(userId));
      
      return {
        id: conv.id,
        otherUser: {
          id: otherUser.id,
          displayName: otherUser.displayName,
          profilePicture: otherUser.profilePicture
        },
        lastMessageAt: conv.lastMessageAt,
        lastMessagePreview: conv.lastMessagePreview,
        isBlocked: isBlocked
      };
    });

    res.json({ conversations: formattedConversations });
  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get or create conversation with another user
exports.getOrCreateConversation = async (req, res) => {
  try {
    const { otherUserId } = req.body;
    const userId = req.user.id;

    if (!otherUserId) {
      return res.status(400).json({ error: 'Other user ID is required' });
    }

    if (otherUserId === userId) {
      return res.status(400).json({ error: 'Cannot create conversation with yourself' });
    }

    // Check if other user exists
    const otherUser = await User.findByPk(otherUserId);
    if (!otherUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Find existing conversation
    let conversation = await Conversation.findOne({
      where: {
        [Op.or]: [
          { participant1Id: userId, participant2Id: otherUserId },
          { participant1Id: otherUserId, participant2Id: userId }
        ]
      }
    });

    // Check if either user has blocked the other
    const currentUser = await User.findByPk(userId);
    const isBlocked = (currentUser.blockedUsers && currentUser.blockedUsers.includes(otherUserId)) ||
                      (otherUser.blockedUsers && otherUser.blockedUsers.includes(userId));
    
    // If blocked, only allow access to existing conversations, not creating new ones
    if (isBlocked && !conversation) {
      return res.status(403).json({ error: 'Cannot create conversation with this user' });
    }

    // Create new conversation if doesn't exist and not blocked
    if (!conversation) {
      conversation = await Conversation.create({
        participant1Id: userId,
        participant2Id: otherUserId
      });
    }

    res.json({
      conversation: {
        id: conversation.id,
        otherUser: {
          id: otherUser.id,
          displayName: otherUser.displayName,
          profilePicture: otherUser.profilePicture
        },
        lastMessageAt: conversation.lastMessageAt,
        lastMessagePreview: conversation.lastMessagePreview,
        isBlocked: isBlocked
      }
    });
  } catch (error) {
    console.error('Get or create conversation error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get messages for a conversation
exports.getMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;

    // Verify user is part of conversation
    const conversation = await Conversation.findOne({
      where: {
        id: conversationId,
        [Op.or]: [
          { participant1Id: userId },
          { participant2Id: userId }
        ]
      }
    });

    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Get non-expired messages
    const messages = await Message.findAll({
      where: {
        conversationId,
        expiresAt: {
          [Op.gt]: new Date()
        }
      },
      attributes: ['id', 'conversationId', 'senderId', 'content', 'replyToId', 'reactions', 'createdAt', 'expiresAt'],
      include: [
        {
          model: User,
          as: 'sender',
          attributes: ['id', 'displayName']
        }
      ],
      order: [['createdAt', 'ASC']]
    });

    // Get all replied-to messages
    const replyToIds = messages.map(m => m.replyToId).filter(id => id);
    const repliedMessages = replyToIds.length > 0 ? await Message.findAll({
      where: {
        id: replyToIds
      },
      include: [{
        model: User,
        as: 'sender',
        attributes: ['id', 'displayName']
      }]
    }) : [];

    const repliedMessagesMap = {};
    repliedMessages.forEach(msg => {
      repliedMessagesMap[msg.id] = {
        id: msg.id,
        senderId: msg.senderId,
        content: msg.content,
        sender: {
          id: msg.sender.id,
          displayName: msg.sender.displayName
        }
      };
    });

    // Format messages
    const formattedMessages = messages.map(msg => ({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      content: msg.content,
      replyToId: msg.replyToId,
      replyToMessage: msg.replyToId ? repliedMessagesMap[msg.replyToId] : null,
      createdAt: msg.createdAt,
      expiresAt: msg.expiresAt,
      reactions: msg.reactions || {},
      sender: msg.sender
    }));

    console.log(`Returning ${formattedMessages.length} messages. First message reactions:`, 
                formattedMessages[0]?.reactions);

    res.json({ messages: formattedMessages });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Delete a conversation
exports.deleteConversation = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;

    // Verify user is part of conversation
    const conversation = await Conversation.findOne({
      where: {
        id: conversationId,
        [Op.or]: [
          { participant1Id: userId },
          { participant2Id: userId }
        ]
      }
    });

    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // Delete all messages in conversation
    await Message.destroy({
      where: { conversationId }
    });

    // Delete conversation
    await conversation.destroy();

    res.json({ message: 'Conversation deleted successfully' });
  } catch (error) {
    console.error('Delete conversation error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Delete a specific message
exports.deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;

    // Find message
    const message = await Message.findByPk(messageId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    // Verify user is the sender
    if (message.senderId !== userId) {
      return res.status(403).json({ error: 'You can only delete your own messages' });
    }

    await message.destroy();

    res.json({ message: 'Message deleted successfully' });
  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Add reaction to message
exports.addReaction = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { emoji } = req.body;
    const userId = req.user.id;

    if (!emoji) {
      return res.status(400).json({ error: 'Emoji is required' });
    }

    // Find message
    const message = await Message.findByPk(messageId, {
      include: [{
        model: require('./Message').sequelize.models.Conversation,
        as: 'conversation'
      }]
    });

    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    // Verify user is part of conversation
    const conversation = await Conversation.findByPk(message.conversationId);
    if (conversation.participant1Id !== userId && conversation.participant2Id !== userId) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    // Update reactions - create a new object for Sequelize to detect change
    const reactions = JSON.parse(JSON.stringify(message.reactions || {}));
    if (!reactions[emoji]) {
      reactions[emoji] = [];
    }
    
    // Add user to reaction if not already present
    if (!reactions[emoji].includes(userId)) {
      reactions[emoji].push(userId);
    }

    // Update using raw query with JSONB cast
    const { sequelize } = require('../models');
    await sequelize.query(
      'UPDATE messages SET reactions = :reactions::jsonb WHERE id = :id',
      {
        replacements: { reactions: JSON.stringify(reactions), id: messageId },
        type: sequelize.QueryTypes.UPDATE
      }
    );
    
    // Reload to get fresh data
    await message.reload();

    res.json({ reactions: message.reactions });
  } catch (error) {
    console.error('Add reaction error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Remove reaction from message
exports.removeReaction = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { emoji } = req.body;
    const userId = req.user.id;

    if (!emoji) {
      return res.status(400).json({ error: 'Emoji is required' });
    }

    // Find message
    const message = await Message.findByPk(messageId);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    // Verify user is part of conversation
    const conversation = await Conversation.findByPk(message.conversationId);
    if (conversation.participant1Id !== userId && conversation.participant2Id !== userId) {
      return res.status(403).json({ error: 'Not authorized' });
    }

    // Update reactions - create a new object for Sequelize to detect change
    const reactions = JSON.parse(JSON.stringify(message.reactions || {}));
    if (reactions[emoji]) {
      reactions[emoji] = reactions[emoji].filter(id => id !== userId);
      
      // Remove emoji key if no users left
      if (reactions[emoji].length === 0) {
        delete reactions[emoji];
      }
    }

    // Update using raw query with JSONB cast
    const { sequelize } = require('../models');
    await sequelize.query(
      'UPDATE messages SET reactions = :reactions::jsonb WHERE id = :id',
      {
        replacements: { reactions: JSON.stringify(reactions), id: messageId },
        type: sequelize.QueryTypes.UPDATE
      }
    );
    
    // Reload to get fresh data
    await message.reload();

    res.json({ reactions: message.reactions });
  } catch (error) {
    console.error('Remove reaction error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

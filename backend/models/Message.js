const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Message = sequelize.define('Message', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  conversationId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'conversations',
      key: 'id'
    }
  },
  senderId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'users',
      key: 'id'
    }
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  replyToId: {
    type: DataTypes.UUID,
    allowNull: true,
    references: {
      model: 'messages',
      key: 'id'
    }
  },
  reactions: {
    type: DataTypes.JSONB,
    allowNull: false,
    defaultValue: {}
  },
  createdAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  expiresAt: {
    type: DataTypes.DATE,
    allowNull: false
  }
}, {
  tableName: 'messages',
  timestamps: false,
  indexes: [
    {
      fields: ['conversationId', 'createdAt']
    },
    {
      fields: ['expiresAt']
    }
  ]
});

// Set expiry time before creating message
Message.beforeCreate((message) => {
  const expiryHours = parseFloat(process.env.MESSAGE_EXPIRY_HOURS) || 12;
  message.expiresAt = new Date(Date.now() + expiryHours * 60 * 60 * 1000);
});

module.exports = Message;

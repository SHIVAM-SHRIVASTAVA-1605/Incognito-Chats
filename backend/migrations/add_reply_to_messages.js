const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

async function addReplyToColumn() {
  try {
    console.log('Adding replyToId column to messages table...');
    
    await sequelize.getQueryInterface().addColumn(
      'messages',
      'replyToId',
      {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: 'messages',
          key: 'id'
        },
        onDelete: 'SET NULL'
      }
    );
    
    console.log('✅ Successfully added replyToId column');
    process.exit(0);
  } catch (error) {
    if (error.message.includes('already exists')) {
      console.log('✅ replyToId column already exists');
      process.exit(0);
    } else {
      console.error('❌ Error adding replyToId column:', error);
      process.exit(1);
    }
  }
}

addReplyToColumn();

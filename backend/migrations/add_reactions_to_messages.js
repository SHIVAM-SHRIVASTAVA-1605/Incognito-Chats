const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

async function addReactionsColumn() {
  try {
    console.log('Adding reactions column to messages table...');
    
    await sequelize.getQueryInterface().addColumn(
      'messages',
      'reactions',
      {
        type: DataTypes.JSONB,
        defaultValue: {},
        allowNull: false
      }
    );
    
    console.log('✅ Successfully added reactions column');
    process.exit(0);
  } catch (error) {
    if (error.message.includes('already exists')) {
      console.log('✅ Reactions column already exists');
      process.exit(0);
    } else {
      console.error('❌ Error adding reactions column:', error);
      process.exit(1);
    }
  }
}

addReactionsColumn();

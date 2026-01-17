const { Message } = require('../models');

async function checkReactions() {
  try {
    console.log('Checking messages with reactions...\n');
    
    const messages = await Message.findAll({
      order: [['createdAt', 'DESC']],
      limit: 10
    });
    
    messages.forEach(msg => {
      console.log(`Message ID: ${msg.id}`);
      console.log(`Content: ${msg.content.substring(0, 50)}...`);
      console.log(`Reactions:`, msg.reactions);
      console.log('---');
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkReactions();

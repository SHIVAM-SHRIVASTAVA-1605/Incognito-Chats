require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const sequelize = require('../config/database');

async function testReactions() {
  try {
    console.log('Testing reactions in database...\n');
    
    // Get most recent messages
    const [results] = await sequelize.query(`
      SELECT id, content, reactions 
      FROM messages 
      ORDER BY "createdAt" DESC 
      LIMIT 5
    `);
    
    console.log('Recent messages:');
    results.forEach((row, i) => {
      console.log(`\n${i + 1}. Message ID: ${row.id}`);
      console.log(`   Content: ${row.content.substring(0, 40)}...`);
      console.log(`   Reactions:`, row.reactions);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

testReactions();

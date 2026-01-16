const cron = require('node-cron');
const { Message } = require('../models');
const { Op } = require('sequelize');

class MessageCleanup {
  static startCleanupJob() {
    // Run cleanup every hour
    cron.schedule('0 * * * *', async () => {
      try {
        console.log('Starting message cleanup job...');
        
        const deletedCount = await Message.destroy({
          where: {
            expiresAt: {
              [Op.lt]: new Date()
            }
          }
        });

        console.log(`Message cleanup completed. Deleted ${deletedCount} expired messages.`);
      } catch (error) {
        console.error('Message cleanup error:', error);
      }
    });

    console.log('Message cleanup job scheduled (runs every hour)');
  }
}

module.exports = MessageCleanup;

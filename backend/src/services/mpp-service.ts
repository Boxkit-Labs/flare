import { mppChannelManager } from './mpp-channel-manager.js';
import cron from 'node-cron';

export class MppService {
    /**
     * Initializes the MPP service and background tasks.
     */
    static async init() {
        console.log('[MppService] Initializing MPP lifecycle management...');
        
        // 1. Run immediate cleanup of expired channels on start
        try {
            await mppChannelManager.autoCloseExpiredChannels();
        } catch (err) {
            console.error('[MppService] Initial cleanup failed:', err);
        }

        // 2. Schedule periodic cleanup (every 30 minutes)
        cron.schedule('*/30 * * * *', async () => {
            console.log('[MppService] Running periodic channel cleanup...');
            try {
                await mppChannelManager.autoCloseExpiredChannels();
            } catch (err) {
                console.error('[MppService] Periodic cleanup failed:', err);
            }
        });

        console.log('[MppService] MPP backend tasks scheduled.');
    }
}

import { mppChannelManager } from '../backend/src/services/mpp-channel-manager.js';
import dotenv from 'dotenv';
dotenv.config({ path: 'backend/.env' });

async function debugClose() {
    const userId = '822cc9a0-62e4-4da6-9f82-06ad9bf7d7a2';
    const serviceId = 'crypto-service';

    console.log(`Attempting to close orphaned channel for ${userId}:${serviceId}...`);
    try {
        const result = await mppChannelManager.closeChannel({ userId, serviceId });
        console.log('Success!', result);
    } catch (err) {
        console.error('Failed to close channel:', err);
    }
}

debugClose();

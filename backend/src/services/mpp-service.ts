import { mppChannelManager } from './mpp-channel-manager.js';
import cron from 'node-cron';

export class MppService {
    private static activeSession: { userId: string, serviceId: string } | null = null;

    /**
     * Initializes the MPP service and background tasks.
     */
    static async init() {
        console.log('[MppService] Initializing MPP lifecycle management...');
        // ... (existing init code)
    }

    /**
     * Activates an MPP session for a specific user and service.
     */
    static setSession(userId: string, serviceId: string) {
        this.activeSession = { userId, serviceId };
    }

    /**
     * Clears the current MPP session.
     */
    static clearSession() {
        this.activeSession = null;
    }

    /**
     * Checks if there is an active MPP session.
     */
    static isActive(): boolean {
        return this.activeSession !== null;
    }

    /**
     * Generates an off-chain payment proof for the current session.
     */
    static async makePayment(amountStroops: number): Promise<string | null> {
        if (!this.activeSession) return null;
        try {
            const amountUsdc = (amountStroops / 10_000_000).toString();
            const { proof } = await mppChannelManager.makePayment({
                userId: this.activeSession.userId,
                serviceId: this.activeSession.serviceId,
                amount: amountUsdc
            });
            // We return the full proof JSON because the paywall middleware needs amount+signature
            return proof;
        } catch (err) {
            console.error('[MppService] Payment failed:', err);
            return null;
        }
    }
}


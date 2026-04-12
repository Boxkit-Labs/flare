import { mppChannelManager } from './mpp-channel-manager.js';
import cron from 'node-cron';

export class MppService {
    private static activeSession: { userId: string, serviceId: string } | null = null;

    static async init() {
        console.log('[MppService] Initializing MPP lifecycle management...');

    }

    static setSession(userId: string, serviceId: string) {
        this.activeSession = { userId, serviceId };
    }

    static clearSession() {
        this.activeSession = null;
    }

    static isActive(): boolean {
        return this.activeSession !== null;
    }

    static async makePayment(amountStroops: number): Promise<string | null> {
        if (!this.activeSession) return null;
        try {
            const amountUsdc = (amountStroops / 10_000_000).toString();
            const { proof } = await mppChannelManager.makePayment({
                userId: this.activeSession.userId,
                serviceId: this.activeSession.serviceId,
                amount: amountUsdc
            });

            return proof;
        } catch (err) {
            console.error('[MppService] Payment failed:', err);
            return null;
        }
    }
}


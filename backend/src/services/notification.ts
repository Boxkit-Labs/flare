import admin from 'firebase-admin';
import { getUserById, updateUserFcmToken, markFindingNotified } from '../db/queries.js';
import { WatcherRow } from '../types.js';

export class NotificationService {
    private isEnabled = false;

    constructor() {
        try {
            const projectId = process.env.FIREBASE_PROJECT_ID;
            const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
            const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

            if (!projectId || !privateKey || !clientEmail) {
                console.warn('⚠️ Firebase credentials missing in .env. FCM push notifications disabled.');
                return;
            }

            admin.initializeApp({
                credential: admin.credential.cert({
                    projectId,
                    privateKey,
                    clientEmail,
                }),
            });

            this.isEnabled = true;
            console.log('✅ Firebase Admin initialized. Push notifications enabled.');
        } catch (error) {
            console.warn('⚠️ Failed to initialize Firebase Admin. Push notifications disabled.', error);
        }
    }

    private isWithinDND(dndStart: string | null, dndEnd: string | null): boolean {
        if (!dndStart || !dndEnd) return false;

        const now = new Date();
        const currentHours = now.getUTCHours();
        const currentMins = now.getUTCMinutes();
        const currentTime = currentHours + (currentMins / 60);

        const [startH, startM] = dndStart.split(':').map(Number);
        const [endH, endM] = dndEnd.split(':').map(Number);
        
        const start = startH + (startM / 60);
        const end = endH + (endM / 60);

        if (start <= end) {
            return currentTime >= start && currentTime <= end;
        } else {
            // Spans midnight
            return currentTime >= start || currentTime <= end;
        }
    }

    private async sendPayload(userId: string, payload: any): Promise<void> {
        if (!this.isEnabled) return;

        const user = getUserById(userId) as any;
        if (!user || !user.fcm_token) {
            console.log(`NotificationService: No FCM token for user ${userId}. Skipping.`);
            return;
        }

        try {
            payload.token = user.fcm_token;
            await admin.messaging().send(payload);
        } catch (error: any) {
            console.error(`Firebase messaging error for ${userId}:`, error.message);
            // Invalidate token if it's dead
            if (
                error.code === 'messaging/invalid-registration-token' ||
                error.code === 'messaging/registration-token-not-registered'
            ) {
                console.log(`NotificationService: Invalid token detected. Clearing FCM token for user ${userId}.`);
                updateUserFcmToken(userId, '');
            }
        }
    }

    async sendFindingNotification(userId: string, finding: any, watcher: WatcherRow): Promise<void> {
        const user = getUserById(userId) as any;
        if (!user) return;

        // DND Check
        if (this.isWithinDND(user.dnd_start, user.dnd_end) && watcher.priority !== 'high') {
            console.log(`NotificationService: DND active for user ${userId}. Skipping finding notification.`);
            return;
        }

        const bodyDetail = finding.detail ? finding.detail.substring(0, 100) : 'New finding match.';
        const vText = finding.verified ? "Verified across 2 checks." : "Single check match.";

        const message = {
            notification: {
                title: `${watcher.name} — ${finding.confidence_score}% Confidence`,
                body: `${finding.headline}. ${vText}`
            },
            android: {
                notification: {
                    channel_id: "ghost_findings",
                    priority: "high" as const
                }
            },
            data: {
                type: "finding",
                finding_id: finding.finding_id,
                watcher_id: finding.watcherId || finding.watcher_id,
                deep_link: `/findings/${finding.finding_id}`
            }
        };

        await this.sendPayload(userId, message);
        markFindingNotified(finding.finding_id);
        console.log(`Notification sent to user ${userId}: ${finding.headline}`);
    }

    async sendBriefingNotification(userId: string, briefing: any): Promise<void> {
        const message = {
            notification: {
                title: `☀️ Morning Briefing — ${briefing.total_findings} findings`,
                body: `Saved est. $${(briefing.total_findings * 45).toFixed(0)}. Cost: $${briefing.total_cost_usdc.toFixed(3)}. Score: ${Math.round(50 + (briefing.total_findings * 10))}`
            },
            android: {
                notification: {
                    channel_id: "ghost_briefings"
                }
            },
            data: {
                type: "briefing",
                briefing_id: briefing.briefing_id,
                deep_link: "/briefing"
            }
        };
        await this.sendPayload(userId, message);
        console.log(`Briefing Notification sent to user ${userId}`);
    }

    async sendBudgetWarning(userId: string, watcher: WatcherRow, percentUsed: number): Promise<void> {
        const message = {
            notification: {
                title: `Budget Alert: ${watcher.name}`,
                body: `${percentUsed}% of $${watcher.weekly_budget_usdc} weekly budget used. 2 days at current rate.`
            },
            android: {
                notification: {
                    channel_id: "ghost_budget"
                }
            },
            data: {
                type: "budget_warning",
                watcher_id: watcher.watcher_id,
                deep_link: `/watchers/${watcher.watcher_id}`
            }
        };
        await this.sendPayload(userId, message);
        console.log(`Budget Warning Notification sent to user ${userId} for watcher ${watcher.watcher_id}`);
    }

    async sendBudgetExhausted(userId: string, watcher: WatcherRow): Promise<void> {
        const message = {
            notification: {
                title: `Watcher Paused: ${watcher.name}`,
                body: `Weekly budget of $${watcher.weekly_budget_usdc} reached. Tap to refill.`
            },
            data: {
                type: "budget_exhausted",
                watcher_id: watcher.watcher_id,
                deep_link: `/watchers/${watcher.watcher_id}`
            }
        };
        await this.sendPayload(userId, message);
        console.log(`Budget Exhausted Notification sent to user ${userId} for watcher ${watcher.watcher_id}`);
    }

    async sendLowBalance(userId: string, balance: string): Promise<void> {
        const message = {
            notification: {
                title: "Wallet Running Low",
                body: `Balance: $${balance} USDC. Your watchers may pause soon.`
            },
            android: {
                notification: {
                    channel_id: "ghost_budget"
                }
            },
            data: {
                type: "low_balance",
                deep_link: "/wallet"
            }
        };
        await this.sendPayload(userId, message);
        console.log(`Low Balance Notification sent to user ${userId}`);
    }

    async sendWeeklySummary(userId: string, stats: any): Promise<void> {
        const message = {
            notification: {
                title: "👻 Weekly Ghost Report",
                body: `Score: ${stats.score}. Saved: $${stats.saved}. Cost: $${stats.cost}. ${stats.txCount} Stellar transactions.`
            },
            android: {
                notification: {
                    channel_id: "ghost_weekly"
                }
            },
            data: {
                type: "weekly_summary",
                deep_link: "/wallet"
            }
        };
        await this.sendPayload(userId, message);
        console.log(`Weekly Summary Notification sent to user ${userId}`);
    }
}

export const notificationService = new NotificationService();

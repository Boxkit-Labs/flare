import admin from 'firebase-admin';
import { getUserById, updateUserFcmToken, markFindingNotified, createNotification } from '../db/queries.js';
import { WatcherRow } from '../types.js';

export class NotificationService {
    private isEnabled = false;

    constructor() {
        try {
            const projectId = process.env.FIREBASE_PROJECT_ID;
            const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
            const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;

            if (!projectId || !privateKey || !clientEmail) {
                console.warn('Warning: Firebase credentials missing in .env. FCM push notifications disabled.');
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
            console.log('OK: Firebase Admin initialized. Push notifications enabled.');
        } catch (error) {
            console.warn('Warning: Failed to initialize Firebase Admin. Push notifications disabled.', error);
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

            return currentTime >= start || currentTime <= end;
        }
    }

    private async sendPayload(userId: string, payload: any): Promise<void> {
        if (!this.isEnabled) return;

        const user = await getUserById(userId) as any;
        if (!user || !user.fcm_token) {
            console.log(`NotificationService: No FCM token for user ${userId}. Skipping.`);
            return;
        }

        try {
            payload.token = user.fcm_token;
            await admin.messaging().send(payload);
        } catch (error: any) {
            console.error(`Firebase messaging error for ${userId}:`, error.message);

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
        const user = await getUserById(userId) as any;
        if (!user) return;

        // Event-specific notification path
        if (watcher.type === 'event') {
            await this.sendEventFindingNotification(userId, finding, watcher, user);
            return;
        }

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
                    channel_id: "flare_findings",
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

        await createNotification({
            user_id: userId,
            title: message.notification.title,
            body: message.notification.body,
            type: 'finding',
            data_id: finding.finding_id
        });

        console.log(`Notification sent to user ${userId}: ${finding.headline}`);
    }

    private async sendEventFindingNotification(userId: string, finding: any, watcher: WatcherRow, user: any): Promise<void> {
        const findingData = finding.data || {};
        const params = typeof watcher.parameters === 'string' ? JSON.parse(watcher.parameters) : (watcher.parameters || {});

        // ── Smart notification timing ──
        const eventDate = params.eventDate ? new Date(params.eventDate) : null;
        const now = new Date();
        const daysUntilEvent = eventDate ? (eventDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24) : null;

        const isUrgentEvent = daysUntilEvent !== null && daysUntilEvent < 3;
        const isDistantEvent = daysUntilEvent !== null && daysUntilEvent > 14;
        const isAvailabilityChange = finding.type === 'threshold_crossed' &&
            (finding.headline?.includes('BACK') || finding.headline?.includes('sold out') || finding.headline?.includes('almost sold out'));
        const isHighPriority = watcher.priority === 'high' || finding.headline?.includes('CANCELLED') || finding.headline?.includes('ALL-TIME LOW');

        // Immediate send bypass: urgent events + availability changes always send
        const bypassDND = isUrgentEvent || isAvailabilityChange;

        // Batch into briefing for distant, non-urgent events
        if (isDistantEvent && !isHighPriority && !isAvailabilityChange) {
            console.log(`[EventNotification] Event >14 days away, batching finding ${finding.finding_id} into briefing.`);
            await createNotification({
                user_id: userId,
                title: this.buildEventTitle(finding, findingData),
                body: this.buildEventBody(finding, findingData),
                type: 'finding',
                data_id: finding.finding_id
            });
            markFindingNotified(finding.finding_id);
            return;
        }

        // DND check (bypass for urgent events and availability)
        if (!bypassDND && this.isWithinDND(user.dnd_start, user.dnd_end) && !isHighPriority) {
            console.log(`[EventNotification] DND active for user ${userId}. Skipping push.`);
            await createNotification({
                user_id: userId,
                title: this.buildEventTitle(finding, findingData),
                body: this.buildEventBody(finding, findingData),
                type: 'finding',
                data_id: finding.finding_id
            });
            markFindingNotified(finding.finding_id);
            return;
        }

        const title = this.buildEventTitle(finding, findingData);
        const body = this.buildEventBody(finding, findingData);

        const bookingUrl = findingData.url || findingData.eventUrl || params.eventUrl || '';
        const platform = findingData.platform || params.platform || '';
        const externalId = findingData.externalId || params.externalId || '';

        const message: any = {
            notification: { title, body },
            android: {
                notification: {
                    channel_id: isUrgentEvent ? "flare_urgent" : "flare_findings",
                    priority: "high" as const,
                },
                data: {
                    actions: JSON.stringify([
                        { action: 'view_details', title: 'View Details' },
                        ...(bookingUrl ? [{ action: 'book_now', title: 'Book Now', url: bookingUrl }] : [])
                    ])
                }
            },
            data: {
                type: "event_finding",
                finding_id: finding.finding_id,
                watcher_id: finding.watcher_id || watcher.watcher_id,
                platform,
                external_id: externalId,
                booking_url: bookingUrl,
                deep_link: `/findings/${finding.finding_id}`
            }
        };

        await this.sendPayload(userId, message);
        markFindingNotified(finding.finding_id);

        await createNotification({
            user_id: userId,
            title,
            body,
            type: 'finding',
            data_id: finding.finding_id
        });

        console.log(`[EventNotification] Push sent to ${userId}: ${title}`);
    }

    private buildEventTitle(finding: any, data: any): string {
        const eventName = data.eventName || data.name || 'Event';
        const tierName = data.tierName || '';
        const currency = data.currency || '';
        const headline = finding.headline || '';

        // Cancelled / Postponed
        if (headline.includes('CANCELLED')) return `🎫 ${eventName} — Cancelled`;
        if (headline.includes('POSTPONED')) return `🎫 ${eventName} — Postponed`;

        // All-time low
        if (headline.includes('ALL-TIME LOW')) return `🎫 All-Time Low: ${tierName} at ${currency} ${data.currentPrice}`;

        // Almost sold out
        if (headline.includes('almost sold out')) return `🎫 Almost Gone: ${data.quantityRemaining} ${tierName} left!`;

        // Back in stock
        if (headline.includes('BACK')) return `🎫 Back in Stock: ${tierName} for ${eventName}`;

        // Sold out
        if (headline.includes('SOLD OUT')) return `🎫 Sold Out: ${tierName} for ${eventName}`;

        // Price drop (percentage)
        if (data.dropPercent) return `🎫 ${tierName} Down ${Math.round(data.dropPercent)}%: ${currency} ${data.newPrice}`;

        // Price below threshold
        if (data.targetPrice) return `🎫 ${tierName} Hit Your Target: ${currency} ${data.currentPrice}`;

        // New listing
        if (finding.type === 'new_listing') {
            const newEvents = data.newEvents || [];
            if (newEvents.length > 0) return `🎫 New Event: ${newEvents[0].name}`;
            return `🎫 New Events Found`;
        }

        return `🎫 ${eventName} — Update`;
    }

    private buildEventBody(finding: any, data: any): string {
        const detail = finding.detail || '';
        const eventName = data.eventName || data.name || '';
        const tierName = data.tierName || '';
        const currency = data.currency || '';

        // Cancelled
        if (detail.includes('cancelled')) return `${eventName} has been cancelled. Check for refund options.`;

        // Postponed
        if (detail.includes('postponed')) return `${eventName} has been postponed. No new date announced yet.`;

        // Almost sold out
        if (data.quantityRemaining !== undefined && detail.includes('remaining'))
            return `Only ${data.quantityRemaining} ${tierName} tickets remaining. Don't miss out!`;

        // Back in stock
        if (detail.includes('available again'))
            return `${tierName} tickets are available again${data.currentPrice ? ` at ${currency} ${data.currentPrice}` : ''}. Grab them before they sell out!`;

        // All-time low
        if (detail.includes('lowest price ever'))
            return `${tierName} tickets just hit their lowest recorded price: ${currency} ${data.currentPrice}.`;

        // Price drop by percentage
        if (data.dropPercent && data.oldPrice)
            return `${tierName} dropped from ${currency} ${data.oldPrice} to ${currency} ${data.newPrice} (${Math.round(data.dropPercent)}% off).`;

        // Price below threshold
        if (data.targetPrice)
            return `${tierName} is now ${currency} ${data.currentPrice}, below your ${currency} ${data.targetPrice} target.`;

        // New listing
        if (finding.type === 'new_listing') {
            const newEvents = data.newEvents || [];
            if (newEvents.length === 1) return `${newEvents[0].name} — tap to view details.`;
            if (newEvents.length > 1) return `${newEvents.length} new events matching your search. Tap to browse.`;
        }

        // Sold out
        if (detail.includes('no longer available'))
            return `${tierName} tickets have sold out. Consider other tiers.`;

        return detail.substring(0, 150);
    }

    async sendBriefingNotification(userId: string, briefing: any): Promise<void> {
        const message = {
            notification: {
                title: `Morning Briefing - ${briefing.total_findings} findings`,
                body: `Saved est. $${(briefing.total_findings * 45).toFixed(0)}. Cost: $${briefing.total_cost_usdc.toFixed(3)}. Score: ${Math.round(50 + (briefing.total_findings * 10))}`
            },
            android: {
                notification: {
                    channel_id: "flare_briefings"
                }
            },
            data: {
                type: "briefing",
                briefing_id: briefing.briefing_id,
                deep_link: "/briefing"
            }
        };
        await this.sendPayload(userId, message);

        await createNotification({
            user_id: userId,
            title: message.notification.title,
            body: message.notification.body,
            type: 'briefing',
            data_id: briefing.briefing_id
        });

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
                    channel_id: "flare_budget"
                }
            },
            data: {
                type: "budget_warning",
                watcher_id: watcher.watcher_id,
                deep_link: `/watchers/${watcher.watcher_id}`
            }
        };
        await this.sendPayload(userId, message);

        await createNotification({
            user_id: userId,
            title: message.notification.title,
            body: message.notification.body,
            type: 'budget_warning',
            data_id: watcher.watcher_id
        });

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

        await createNotification({
            user_id: userId,
            title: message.notification.title,
            body: message.notification.body,
            type: 'budget_exhausted',
            data_id: watcher.watcher_id
        });

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
                    channel_id: "flare_budget"
                }
            },
            data: {
                type: "low_balance",
                deep_link: "/wallet"
            }
        };
        await this.sendPayload(userId, message);

        await createNotification({
            user_id: userId,
            title: message.notification.title,
            body: message.notification.body,
            type: 'low_balance',
            data_id: null
        });

        console.log(`Low Balance Notification sent to user ${userId}`);
    }

    async sendWeeklySummary(userId: string, stats: any): Promise<void> {
        const message = {
            notification: {
                title: "Weekly Flare Report",
                body: `Score: ${stats.score}. Saved: $${stats.saved}. Cost: $${stats.cost}. ${stats.txCount} Stellar transactions.`
            },
            android: {
                notification: {
                    channel_id: "flare_weekly"
                }
            },
            data: {
                type: "weekly_summary",
                deep_link: "/wallet"
            }
        };
        await this.sendPayload(userId, message);

        await createNotification({
            user_id: userId,
            title: message.notification.title,
            body: message.notification.body,
            type: 'weekly_summary',
            data_id: null
        });

        console.log(`Weekly Summary Notification sent to user ${userId}`);
    }
}

export const notificationService = new NotificationService();

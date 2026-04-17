import { Router, Request, Response } from 'express';
import { randomUUID } from 'node:crypto';
import * as queries from '../db/queries.js';
import { scheduler } from '../server.js';
import { mppChannelManager } from '../services/mpp-channel-manager.js';

const router = Router();

import { WatcherRow } from '../types.js';

interface Check {
    check_id: string;
    watcher_id: string;
    status: string;
    message?: string;
    cost_usdc: number;
    data?: any;
    created_at: string;
}

interface Finding {
    finding_id: string;
    watcher_id: string;
    check_id: string;
    title: string;
    description: string;
    data?: any;
    is_notified: number;
    created_at: string;
}

const getMostRecentMonday = () => {
    const now = new Date();
    const day = now.getUTCDay();
    const diff = (day === 0 ? 6 : day - 1);
    const monday = new Date(now);
    monday.setUTCDate(now.getUTCDate() - diff);
    monday.setUTCHours(0, 0, 0, 0);
    return monday.toISOString();
};

router.post('/', async (req: Request, res: Response) => {
    try {
        const {
            user_id, name, type, parameters, alert_conditions,
            check_interval_minutes, weekly_budget_usdc, priority
        } = req.body;

        const allowedTypes = ['flight', 'crypto', 'news', 'product', 'job', 'custom', 'stock', 'realestate', 'sports', 'event'];

        if (!user_id || !type) {
            return res.status(400).json({ error: 'Missing required fields: user_id and type are required' });
        }

        if (!allowedTypes.includes(type)) {
            return res.status(400).json({ error: `Invalid type. Must be one of: ${allowedTypes.join(', ')}` });
        }

        // ─── Event-specific validation ──────────────────────────────
        let finalParams = parameters || {};
        let finalConditions = alert_conditions || {};
        let finalName = name;
        let finalInterval = check_interval_minutes;
        let finalBudget = weekly_budget_usdc;

        if (type === 'event') {
            const params = parameters || {};
            const conditions = alert_conditions || {};

            // Mode validation
            if (!params.mode || !['specific_event', 'search'].includes(params.mode)) {
                return res.status(400).json({ error: 'Event watchers require mode: "specific_event" or "search"' });
            }

            // ── specific_event mode validation ──
            if (params.mode === 'specific_event') {
                if (!params.externalId || typeof params.externalId !== 'string' || params.externalId.trim() === '') {
                    return res.status(400).json({ error: 'specific_event mode requires externalId as a non-empty string' });
                }

                const validPlatforms = ['ticketmaster', 'seatgeek', 'eventbrite'];
                if (!params.platform || !validPlatforms.includes(params.platform.toLowerCase())) {
                    return res.status(400).json({ error: `specific_event mode requires platform: ${validPlatforms.join(', ')}` });
                }

                if (!params.eventName || typeof params.eventName !== 'string' || params.eventName.trim() === '') {
                    return res.status(400).json({ error: 'specific_event mode requires eventName for display purposes' });
                }

                // Normalize watchTiers
                if (params.watchTiers !== undefined && params.watchTiers !== 'all') {
                    if (!Array.isArray(params.watchTiers) || params.watchTiers.some((t: any) => typeof t !== 'string')) {
                        return res.status(400).json({ error: 'watchTiers must be "all" or an array of tier name strings' });
                    }
                }
                params.watchTiers = params.watchTiers || 'all';

                // Validate eventDate if provided
                if (params.eventDate) {
                    const d = new Date(params.eventDate);
                    if (isNaN(d.getTime())) {
                        return res.status(400).json({ error: 'eventDate must be a valid ISO date string' });
                    }
                }

                // Reject newListingAlert for specific_event
                if (conditions.newListingAlert) {
                    return res.status(400).json({ error: 'newListingAlert is only allowed for search mode watchers' });
                }
            }

            // ── search mode validation ──
            if (params.mode === 'search') {
                if (!params.q && !params.city && !params.category) {
                    return res.status(400).json({ error: 'Search mode requires at least one of: q (query), city, or category' });
                }

                // Platform defaults to 'all'
                params.platform = params.platform || 'all';
            }

            // ── Alert conditions validation ──
            let conditionCount = 0;

            if (conditions.priceBelow !== undefined) {
                if (typeof conditions.priceBelow !== 'number' || conditions.priceBelow <= 0) {
                    return res.status(400).json({ error: 'priceBelow must be a positive number' });
                }
                conditionCount++;
            }

            if (conditions.priceDropPercent !== undefined) {
                if (typeof conditions.priceDropPercent !== 'number' || conditions.priceDropPercent < 1 || conditions.priceDropPercent > 99) {
                    return res.status(400).json({ error: 'priceDropPercent must be between 1 and 99' });
                }
                conditionCount++;
            }

            if (conditions.almostSoldOutThreshold !== undefined) {
                if (typeof conditions.almostSoldOutThreshold !== 'number' || conditions.almostSoldOutThreshold < 1 || conditions.almostSoldOutThreshold > 100) {
                    return res.status(400).json({ error: 'almostSoldOutThreshold must be between 1 and 100' });
                }
            }
            conditions.almostSoldOutThreshold = conditions.almostSoldOutThreshold || 10;

            if (conditions.availabilityAlert !== undefined) {
                if (typeof conditions.availabilityAlert !== 'boolean') {
                    return res.status(400).json({ error: 'availabilityAlert must be a boolean' });
                }
            }
            conditions.availabilityAlert = conditions.availabilityAlert ?? false;

            if (conditions.newListingAlert) conditionCount++;
            if (conditions.availabilityAlert) conditionCount++;

            // ── Free event safeguards ──
            if (params.isFree === true) {
                if (conditions.priceBelow !== undefined) {
                    return res.status(400).json({ error: 'Price alerts (priceBelow) cannot be set on free events. Free events only support availability and listing alerts.' });
                }
                if (conditions.priceDropPercent !== undefined) {
                    return res.status(400).json({ error: 'Price alerts (priceDropPercent) cannot be set on free events. Free events only support availability and listing alerts.' });
                }
                // Auto-enable availability alert for free events
                conditions.availabilityAlert = true;
                conditionCount++;
            }

            if (conditionCount === 0) {
                return res.status(400).json({ error: 'At least one alert condition must be enabled (priceBelow, priceDropPercent, availabilityAlert, or newListingAlert)' });
            }

            // ── Smart check interval defaults ──
            if (!finalInterval) {
                if (params.eventDate) {
                    const eventDate = new Date(params.eventDate);
                    const now = new Date();
                    const daysUntilEvent = (eventDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);

                    if (daysUntilEvent > 30) finalInterval = 720;       // 12 hours
                    else if (daysUntilEvent > 7) finalInterval = 360;   // 6 hours
                    else if (daysUntilEvent > 3) finalInterval = 120;   // 2 hours
                    else finalInterval = 60;                            // 1 hour
                } else {
                    finalInterval = 120; // 2 hours default
                }
            }

            // Weekly budget default
            finalBudget = finalBudget || 0.35;

            // ── Auto-generate display name ──
            if (!finalName) {
                if (params.mode === 'specific_event') {
                    const platformDisplay: Record<string, string> = {
                        ticketmaster: 'Ticketmaster',
                        seatgeek: 'SeatGeek',
                        eventbrite: 'Eventbrite'
                    };
                    finalName = `${params.eventName} (${platformDisplay[params.platform.toLowerCase()] || params.platform})`;
                } else {
                    const parts: string[] = [];
                    if (params.category) parts.push(params.category.charAt(0).toUpperCase() + params.category.slice(1));
                    if (params.city) parts.push(`in ${params.city}`);
                    if (parts.length === 0 && params.q) parts.push(`"${params.q}"`);
                    finalName = parts.join(' ') || 'Event Search';
                }
            }

            finalParams = params;
            finalConditions = conditions;

        } else {
            // Non-event types: existing validation
            if (!name || !parameters || !alert_conditions || !check_interval_minutes || !weekly_budget_usdc) {
                return res.status(400).json({ error: 'Missing required fields' });
            }

            if (check_interval_minutes < 1) {
                return res.status(400).json({ error: 'check_interval_minutes must be at least 1' });
            }

            if (weekly_budget_usdc <= 0) {
                return res.status(400).json({ error: 'weekly_budget_usdc must be positive' });
            }

            finalInterval = check_interval_minutes;
            finalBudget = weekly_budget_usdc;
        }

        const user = await queries.getUserById(user_id);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const watcherId = randomUUID();
        const now = new Date();
        const nextCheck = now;

        const newWatcher = {
            watcherId,
            userId: user_id,
            name: finalName,
            type,
            parameters: finalParams,
            alertConditions: finalConditions,
            checkIntervalMinutes: finalInterval,
            weeklyBudgetUsdc: finalBudget,
            priority: priority || 'medium',
            status: 'active'
        };

        await queries.createWatcher(newWatcher);

        await queries.updateWatcher(watcherId, {
            week_start: getMostRecentMonday(),
            next_check_at: nextCheck.toISOString()
        });

        const insertedWatcher = await queries.getWatcherById(watcherId) as WatcherRow;
        scheduler.addWatcher(insertedWatcher);
        res.status(201).json(insertedWatcher);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/', async (req: Request, res: Response) => {
    try {
        const userId = req.query.user_id as string;
        if (!userId) return res.status(400).json({ error: 'user_id query param is required' });

        const watchers = await queries.getWatchersByUserId(userId) as WatcherRow[];

        const enhancedWatchers = watchers.map((w: WatcherRow) => {
            const budgetPercentUsed = w.weekly_budget_usdc > 0
                ? (w.spent_this_week_usdc / w.weekly_budget_usdc) * 100
                : 0;
            return { ...w, budget_percent_used: budgetPercentUsed };
        });

        res.json(enhancedWatchers);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/:id', async (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const watcher = await queries.getWatcherById(watcherId) as WatcherRow | undefined;
        if (!watcher) return res.status(404).json({ error: 'Watcher not found' });

        const checks = await queries.getChecksByWatcherId(watcherId, 10) as Check[];
        const findings = (await queries.getFindingsByWatcherId(watcherId) as Finding[]).slice(0, 5);

        res.json({
            ...watcher,
            recent_checks: checks,
            recent_findings: findings
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.put('/:id', async (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const existing = await queries.getWatcherById(watcherId) as WatcherRow | undefined;
        if (!existing) return res.status(404).json({ error: 'Watcher not found' });

        const allowedUpdates = ['name', 'parameters', 'alert_conditions', 'check_interval_minutes', 'weekly_budget_usdc', 'priority'];
        const updates: any = {};

        Object.keys(req.body).forEach(key => {
            if (allowedUpdates.includes(key)) {
                updates[key] = req.body[key];
            }
        });

        if (updates.check_interval_minutes && updates.check_interval_minutes !== existing.check_interval_minutes) {
             const now = new Date();
             updates.next_check_at = new Date(now.getTime() + updates.check_interval_minutes * 60000).toISOString();
        }

        await queries.updateWatcher(watcherId, updates);
        const updatedWatcher = await queries.getWatcherById(watcherId) as WatcherRow;
        if (updates.check_interval_minutes && updates.check_interval_minutes !== existing.check_interval_minutes) {
             scheduler.rescheduleWatcher(updatedWatcher);
        }
        res.json(updatedWatcher);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/:id/toggle', async (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const watcher = await queries.getWatcherById(watcherId) as WatcherRow | undefined;
        if (!watcher) return res.status(404).json({ error: 'Watcher not found' });

        let newStatus = '';
        const updates: any = {};

        if (watcher.status === 'active') {
            newStatus = 'paused_manual';
        } else if (watcher.status === 'paused_manual' || watcher.status === 'error') {
            newStatus = 'active';

            const now = new Date();
            updates.next_check_at = new Date(now.getTime() + watcher.check_interval_minutes * 60000).toISOString();
        } else {
            return res.status(400).json({ error: `Cannot toggle watcher in status: ${watcher.status}` });
        }

        updates.status = newStatus;
        await queries.updateWatcher(watcherId, updates);
        const updatedWatcher = await queries.getWatcherById(watcherId) as WatcherRow;

        if (newStatus === 'active') {
            scheduler.addWatcher(updatedWatcher);
        } else {
            scheduler.removeWatcher(watcherId);
        }

        res.json(updatedWatcher);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.delete('/:id', async (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;

        const watcher = await queries.getWatcherById(watcherId) as WatcherRow | undefined;
        if (watcher) {
            try {

                const allUserWatchers = await queries.getWatchersByUserId(watcher.user_id);

                const sameTypeWatchers = allUserWatchers.filter((w: WatcherRow) => w.type === watcher.type && w.watcher_id !== watcherId && w.status === 'active');

                if (sameTypeWatchers.length === 0) {
                    console.log(`[MPP] Last ${watcher.type} watcher for user ${watcher.user_id} being deleted. Attempting to close/settle channel.`);

                    await mppChannelManager.closeChannel({
                        userId: watcher.user_id,
                        serviceId: `${watcher.type}-service`
                    });
                    console.log(`[MPP] Channel closed and settled successfully for deleted watcher: ${watcherId}. Final balance should reflect on-chain.`);
                } else {
                    console.log(`[MPP] User still has ${sameTypeWatchers.length} active ${watcher.type} watcher(s). Keeping channel open for remaining stream to optimize fees.`);
                }
            } catch (closeErr: any) {

                if (!closeErr.message.includes('No active channel') && !closeErr.message.includes('No proof')) {
                    console.error(`[MPP] Error closing channel for deleted watcher ${watcherId}:`, closeErr.message);
                }
            }
        }

        const result = await queries.deleteWatcher(watcherId);
        if (result.rowCount === 0) return res.status(404).json({ error: 'Watcher not found' });

        res.json({ success: true });
        scheduler.removeWatcher(watcherId);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/:id/check', async (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const watcher = await queries.getWatcherById(watcherId) as WatcherRow | undefined;
        if (!watcher) return res.status(404).json({ error: 'Watcher not found' });

        console.log(`Manual check triggered for watcher: ${watcher.name} (${watcherId})`);

        await scheduler.executeScheduledCheck(watcherId, watcher.check_interval_minutes * 60 * 1000);

        const updatedWatcher = await queries.getWatcherById(watcherId);
        res.json({ message: 'Check executed', watcher: updatedWatcher });
    } catch (error: any) {
        console.error('Manual check failed:', error);
        res.status(500).json({ error: error.message });
    }
});

export default router;

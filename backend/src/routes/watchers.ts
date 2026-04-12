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

        if (!user_id || !name || !type || !parameters || !alert_conditions || !check_interval_minutes || !weekly_budget_usdc) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        const allowedTypes = ['flight', 'crypto', 'news', 'product', 'job', 'custom', 'stock', 'realestate', 'sports'];
        if (!allowedTypes.includes(type)) {
            return res.status(400).json({ error: 'Invalid type' });
        }

        if (check_interval_minutes < 1) {
            return res.status(400).json({ error: 'check_interval_minutes must be at least 1' });
        }

        if (weekly_budget_usdc <= 0) {
            return res.status(400).json({ error: 'weekly_budget_usdc must be positive' });
        }

        const user = await queries.getUserById(user_id);
        if (!user) return res.status(404).json({ error: 'User not found' });

        const watcherId = randomUUID();
        const now = new Date();
        const nextCheck = new Date(now.getTime() + check_interval_minutes * 60000);

        const newWatcher = {
            watcherId,
            userId: user_id,
            name,
            type,
            parameters,
            alertConditions: alert_conditions,
            checkIntervalMinutes: check_interval_minutes,
            weeklyBudgetUsdc: weekly_budget_usdc,
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

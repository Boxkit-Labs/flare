import { Router, Request, Response } from 'express';
import { randomUUID } from 'node:crypto';
import * as queries from '../db/queries.js';
import { scheduler } from '../server.js';

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

/**
 * Helper to calculate the most recent Monday at 00:00:00 UTC.
 */
const getMostRecentMonday = () => {
    const now = new Date();
    const day = now.getUTCDay(); // 0 is Sunday, 1 is Monday
    const diff = (day === 0 ? 6 : day - 1); // Days since last Monday
    const monday = new Date(now);
    monday.setUTCDate(now.getUTCDate() - diff);
    monday.setUTCHours(0, 0, 0, 0);
    return monday.toISOString();
};

/**
 * POST /api/watchers
 * Create a new watcher.
 */
router.post('/', async (req: Request, res: Response) => {
    try {
        const {
            user_id, name, type, parameters, alert_conditions,
            check_interval_minutes, weekly_budget_usdc, priority
        } = req.body;

        // Basic Validation
        if (!user_id || !name || !type || !parameters || !alert_conditions || !check_interval_minutes || !weekly_budget_usdc) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        const allowedTypes = ['flight', 'crypto', 'news', 'product', 'job', 'custom'];
        if (!allowedTypes.includes(type)) {
            return res.status(400).json({ error: 'Invalid type' });
        }

        if (check_interval_minutes < 1) {
            return res.status(400).json({ error: 'check_interval_minutes must be at least 1' });
        }

        if (weekly_budget_usdc <= 0) {
            return res.status(400).json({ error: 'weekly_budget_usdc must be positive' });
        }

        // Verify User Exists
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

        // Update timestamps and calculated fields that weren't in the base create query
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

/**
 * GET /api/watchers
 * List watchers for a user with computed fields.
 */
router.get('/', async (req: Request, res: Response) => {
    try {
        const userId = req.query.user_id as string;
        if (!userId) return res.status(400).json({ error: 'user_id query param is required' });

        const watchers = await queries.getWatchersByUserId(userId) as WatcherRow[];
        
        const enhancedWatchers = watchers.map(w => {
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

/**
 * GET /api/watchers/:id
 * Single watcher detail with last 10 checks and last 5 findings.
 */
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

/**
 * PUT /api/watchers/:id
 * Partial update for a watcher.
 */
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

        // Recalculate next_check if interval changed
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

/**
 * POST /api/watchers/:id/toggle
 * Toggles active/paused_manual state.
 */
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
            // Reset next check to now + interval when unpausing
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

/**
 * DELETE /api/watchers/:id
 * Deletes a watcher record.
 */
router.delete('/:id', async (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const result = await queries.deleteWatcher(watcherId);
        if (result.rowCount === 0) return res.status(404).json({ error: 'Watcher not found' });
        
        res.json({ success: true });
        scheduler.removeWatcher(watcherId);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/watchers/:id/check
 * Manually triggers a check for a watcher.
 */
router.post('/:id/check', async (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const watcher = await queries.getWatcherById(watcherId) as WatcherRow | undefined;
        if (!watcher) return res.status(404).json({ error: 'Watcher not found' });

        console.log(`Manual check triggered for watcher: ${watcher.name} (${watcherId})`);
        
        // Execute the check immediately through the scheduler/executor
        // We use a small interval here just as a placeholder, the execution isn't rescheduled by this call
        // although executeScheduledCheck DOES reschedule if status is active.
        await scheduler.executeScheduledCheck(watcherId, watcher.check_interval_minutes * 60 * 1000);
        
        const updatedWatcher = await queries.getWatcherById(watcherId);
        res.json({ message: 'Check executed', watcher: updatedWatcher });
    } catch (error: any) {
        console.error('Manual check failed:', error);
        res.status(500).json({ error: error.message });
    }
});

export default router;

import { Router, Request, Response } from 'express';
import { randomUUID } from 'node:crypto';
import * as queries from '../db/queries';

const router = Router();

interface Watcher {
    watcher_id: string;
    user_id: string;
    name: string;
    type: string;
    parameters: any;
    alert_conditions: any;
    check_interval_minutes: number;
    weekly_budget_usdc: number;
    spent_this_week_usdc: number;
    week_start: string;
    priority: string;
    status: string;
    next_check_at: string;
    created_at: string;
    updated_at: string;
}

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

        if (check_interval_minutes < 15) {
            return res.status(400).json({ error: 'check_interval_minutes must be at least 15' });
        }

        if (weekly_budget_usdc <= 0) {
            return res.status(400).json({ error: 'weekly_budget_usdc must be positive' });
        }

        // Verify User Exists
        const user = queries.getUserById(user_id);
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

        queries.createWatcher(newWatcher);

        // Update timestamps and calculated fields that weren't in the base create query
        queries.updateWatcher(watcherId, {
            week_start: getMostRecentMonday(),
            next_check_at: nextCheck.toISOString()
        });

        res.status(201).json(queries.getWatcherById(watcherId));
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/watchers
 * List watchers for a user with computed fields.
 */
router.get('/', (req: Request, res: Response) => {
    try {
        const userId = req.query.user_id as string;
        if (!userId) return res.status(400).json({ error: 'user_id query param is required' });

        const watchers = queries.getWatchersByUserId(userId) as Watcher[];
        
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
router.get('/:id', (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const watcher = queries.getWatcherById(watcherId) as Watcher | undefined;
        if (!watcher) return res.status(404).json({ error: 'Watcher not found' });

        const checks = queries.getChecksByWatcherId(watcherId, 10) as Check[];
        const findings = (queries.getFindingsByWatcherId(watcherId) as Finding[]).slice(0, 5);

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
router.put('/:id', (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const existing = queries.getWatcherById(watcherId) as Watcher | undefined;
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

        queries.updateWatcher(watcherId, updates);
        res.json(queries.getWatcherById(watcherId));
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/watchers/:id/toggle
 * Toggles active/paused_manual state.
 */
router.post('/:id/toggle', (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const watcher = queries.getWatcherById(watcherId) as Watcher | undefined;
        if (!watcher) return res.status(404).json({ error: 'Watcher not found' });

        let newStatus = '';
        const updates: any = {};

        if (watcher.status === 'active') {
            newStatus = 'paused_manual';
        } else if (watcher.status === 'paused_manual') {
            newStatus = 'active';
            // Reset next check to now + interval when unpausing
            const now = new Date();
            updates.next_check_at = new Date(now.getTime() + watcher.check_interval_minutes * 60000).toISOString();
        } else {
            return res.status(400).json({ error: `Cannot toggle watcher in status: ${watcher.status}` });
        }

        updates.status = newStatus;
        queries.updateWatcher(watcherId, updates);
        
        res.json(queries.getWatcherById(watcherId));
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * DELETE /api/watchers/:id
 * Deletes a watcher record.
 */
router.delete('/:id', (req: Request, res: Response) => {
    try {
        const watcherId = req.params.id as string;
        const result = queries.deleteWatcher(watcherId);
        if (result.changes === 0) return res.status(404).json({ error: 'Watcher not found' });
        
        res.json({ success: true });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;

import { Router, Request, Response } from 'express';
import { randomUUID } from 'node:crypto';
import * as queries from '../db/queries';

const router = Router();

/**
 * GET /api/briefings
 * List recent briefings for a user.
 */
router.get('/', (req: Request, res: Response) => {
    try {
        const userId = req.query.user_id as string;
        const limit = parseInt(req.query.limit as string) || 7;
        if (!userId) return res.status(400).json({ error: 'user_id is required' });
        
        const briefings = queries.getBriefingsByUserId(userId, limit);
        res.json(briefings);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/briefings/today
 * Fetch today's briefing.
 */
router.get('/today', (req: Request, res: Response) => {
    try {
        const userId = req.query.user_id as string;
        if (!userId) return res.status(400).json({ error: 'user_id is required' });

        const briefing = queries.getTodayBriefing(userId);
        res.json(briefing || null);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/briefings/generate
 * Placeholder for manual briefing generation.
 */
router.post('/generate', async (req: Request, res: Response) => {
    try {
        const { user_id } = req.body;
        if (!user_id) return res.status(400).json({ error: 'user_id is required' });

        // Placeholder data logic
        const recentFindings = queries.getFindingsByUserId(user_id, 3);
        const stats = queries.getSpendingStats(user_id);

        const briefingId = randomUUID();
        const now = new Date();
        const dateStr = now.toISOString().split('T')[0];

        const newBriefing = {
            briefingId,
            userId: user_id,
            date: dateStr,
            periodStart: new Date(now.getTime() - 24 * 60 * 60000).toISOString(),
            periodEnd: now.toISOString(),
            totalChecks: (stats as any).total_checks_today || 12, // Placeholder fallback
            totalFindings: recentFindings.length,
            totalCostUsdc: (stats as any).spent_today || 0.15,
            findingsJson: recentFindings,
            watcherSummariesJson: [{ watcher_id: 'all', summary: 'Everything looks normal.' }],
            generatedSummary: recentFindings.length > 0 
                ? `You have ${recentFindings.length} new findings to review from your watchers.`
                : "No significant findings today. Your watchers are monitoring your interests quietly."
        };

        queries.createBriefing(newBriefing);
        res.status(201).json(queries.getTodayBriefing(user_id));
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;

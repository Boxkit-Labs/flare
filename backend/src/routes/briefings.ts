import { Router, Request, Response } from 'express';
import { randomUUID } from 'node:crypto';
import * as queries from '../db/queries.js';
import { briefingGenerator } from '../services/briefing-generator.js';

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

        const newBriefing = await briefingGenerator.generateBriefing(user_id);
        
        res.status(201).json(newBriefing);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;

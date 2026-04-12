import { Router, Request, Response } from 'express';
import * as queries from '../db/queries.js';

const router = Router();

router.get('/', async (req: Request, res: Response) => {
    try {
        const userId = req.query.user_id as string;
        const limit = parseInt(req.query.limit as string) || 20;
        const offset = parseInt(req.query.offset as string) || 0;

        if (!userId) return res.status(400).json({ error: 'user_id is required' });

        const findings = await queries.getFindingsByUserId(userId, limit, offset);
        res.json(findings);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/:id', async (req: Request, res: Response) => {
    try {
        const findingId = req.params.id as string;
        const finding = await queries.getFindingDetail(findingId);
        if (!finding) return res.status(404).json({ error: 'Finding not found' });
        res.json(finding);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/:id/read', async (req: Request, res: Response) => {
    try {
        const findingId = req.params.id as string;
        await queries.markFindingRead(findingId);
        res.json({ success: true });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;

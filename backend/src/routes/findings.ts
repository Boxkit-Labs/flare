import { Router, Request, Response } from 'express';
import * as queries from '../db/queries';

const router = Router();

/**
 * GET /api/findings
 * Paginated list of findings for a user.
 */
router.get('/', (req: Request, res: Response) => {
    try {
        const userId = req.query.user_id as string;
        const limit = parseInt(req.query.limit as string) || 20;
        const offset = parseInt(req.query.offset as string) || 0;

        if (!userId) return res.status(400).json({ error: 'user_id is required' });

        const findings = queries.getFindingsByUserId(userId, limit, offset);
        res.json(findings);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * GET /api/findings/:id
 * Detailed finding view with check and watcher info.
 */
router.get('/:id', (req: Request, res: Response) => {
    try {
        const findingId = req.params.id as string;
        const finding = queries.getFindingDetail(findingId);
        if (!finding) return res.status(404).json({ error: 'Finding not found' });
        res.json(finding);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * POST /api/findings/:id/read
 * Mark a finding as read.
 */
router.post('/:id/read', (req: Request, res: Response) => {
    try {
        const findingId = req.params.id as string;
        queries.markFindingRead(findingId);
        res.json({ success: true });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;

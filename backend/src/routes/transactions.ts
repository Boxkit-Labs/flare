import { Router, Request, Response } from 'express';
import * as queries from '../db/queries';

const router = Router();

/**
 * GET /api/transactions
 * Filtering by user_id or watcher_id.
 */
router.get('/', (req: Request, res: Response) => {
    try {
        const userId = req.query.user_id as string;
        const watcherId = req.query.watcher_id as string;
        const limit = parseInt(req.query.limit as string) || 20;
        const offset = parseInt(req.query.offset as string) || 0;

        if (watcherId) {
            const txs = queries.getTransactionsByWatcherId(watcherId, limit, offset);
            return res.json(txs);
        }

        if (userId) {
            const txs = queries.getTransactionsByUserId(userId, limit, offset);
            return res.json(txs);
        }

        return res.status(400).json({ error: 'Either user_id or watcher_id is required' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;

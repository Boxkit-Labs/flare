import { Router } from 'express';
import { getNotificationsByUserId, getUnreadNotificationCount, markNotificationRead } from '../db/queries.js';

const router = Router();

// GET /api/notifications?user_id=...
router.get('/', async (req, res) => {
  try {
    const userId = req.query.user_id as string;
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;

    if (!userId) {
      return res.status(400).json({ error: 'user_id is required' });
    }

    const notifications = await getNotificationsByUserId(userId, limit, offset);
    res.json(notifications);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/notifications/unread-count?user_id=...
router.get('/unread-count', async (req, res) => {
  try {
    const userId = req.query.user_id as string;
    if (!userId) {
      return res.status(400).json({ error: 'user_id is required' });
    }

    const count = await getUnreadNotificationCount(userId);
    res.json({ unread_count: count });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/notifications/:id/read
router.post('/:id/read', async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id } = req.body;

    if (!user_id) {
      return res.status(400).json({ error: 'user_id is required in body' });
    }

    await markNotificationRead(id, user_id);
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;

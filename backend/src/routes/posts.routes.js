import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { toggleLike } from '../controllers/posts.controller.js';

const router = Router();
router.use(requireAuth);

router.post('/:id/like', toggleLike);

export default router;

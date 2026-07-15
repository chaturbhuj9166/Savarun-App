import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { getWardrobeAnalytics } from '../controllers/wardrobe.controller.js';

const router = Router();
router.use(requireAuth);

router.get('/analytics', getWardrobeAnalytics);

export default router;

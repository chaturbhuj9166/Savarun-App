import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { aiLimiter } from '../middleware/rateLimit.js';
import { uploadImage } from '../middleware/upload.js';
import {
  getWardrobeAnalytics,
  autoTagItem,
} from '../controllers/wardrobe.controller.js';

const router = Router();
router.use(requireAuth);

router.get('/analytics', getWardrobeAnalytics);
// AI auto-tag a single clothing photo (shares the AI rate limiter).
router.post('/autotag', aiLimiter, uploadImage.single('image'), autoTagItem);

export default router;

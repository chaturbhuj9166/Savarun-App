import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { aiLimiter } from '../middleware/rateLimit.js';
import { uploadImage } from '../middleware/upload.js';
import { analyzeOutfit, getHistory } from '../controllers/analysis.controller.js';

const router = Router();

// All analysis routes require a logged-in Firebase user.
router.use(requireAuth);

// The Flutter app posts the outfit photo directly (field "image").
router.post('/', aiLimiter, uploadImage.single('image'), analyzeOutfit);
router.get('/history', getHistory);

export default router;

import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { listProducts, trendingProducts, trackClick } from '../controllers/affiliate.controller.js';

const router = Router();
router.use(requireAuth);

router.get('/products', listProducts);
router.get('/trending', trendingProducts);
router.post('/click', trackClick);

export default router;

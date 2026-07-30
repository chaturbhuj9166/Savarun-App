import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import {
  listProducts,
  trendingProducts,
  featuredBrand,
  trackClick,
  submitBrand,
  myBrands,
  submitProduct,
} from '../controllers/affiliate.controller.js';

const router = Router();
router.use(requireAuth);

router.get('/products', listProducts);
router.get('/trending', trendingProducts);
router.get('/featured', featuredBrand);
router.post('/click', trackClick);

// Brand submission (Module 4) — any user can apply; admin approves.
router.post('/brands', submitBrand);
router.get('/my-brands', myBrands);
router.post('/products', submitProduct);

export default router;

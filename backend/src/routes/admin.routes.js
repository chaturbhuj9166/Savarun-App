import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { adminOnly } from '../middleware/adminOnly.js';
import {
  getAnalytics,
  decideBrand,
  setProductVisibility,
  setFeaturedBrand,
  getFitWeights,
  updateFitWeights,
  moderateUser,
  setUserAdmin,
} from '../controllers/admin.controller.js';

const router = Router();

// Every admin route requires a logged-in user WITH the admin claim.
router.use(requireAuth, adminOnly);

router.get('/analytics', getAnalytics);

router.post('/brands/:id/decision', decideBrand);
router.patch('/products/:id/visibility', setProductVisibility);
router.put('/featured-brand', setFeaturedBrand);

router.get('/fit-weights', getFitWeights);
router.put('/fit-weights', updateFitWeights);

router.post('/users/:uid/moderate', moderateUser);
router.post('/users/:uid/set-admin', setUserAdmin);

export default router;

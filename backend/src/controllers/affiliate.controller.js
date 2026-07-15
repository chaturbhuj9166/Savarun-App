import { z } from 'zod';
import { db, admin } from '../config/firebase.js';
import { ApiError } from '../utils/ApiError.js';
import { asyncHandler } from '../utils/asyncHandler.js';

/**
 * GET /api/affiliate/products
 * Approved, visible brand products for the Shop tab (Module 4).
 * Optional filters: ?category=footwear&limit=30
 *
 * Firestore: products/{productId}
 *   product = { brandId, brandName, name, price, imageUrl, category,
 *               websiteUrl, approved, hidden, clicks, createdAt }
 */
export const listProducts = asyncHandler(async (req, res) => {
  const category = (req.query.category || '').toString().trim().toLowerCase();
  const limit = Math.min(Number(req.query.limit) || 30, 60);

  let query = db.collection('products').where('approved', '==', true).where('hidden', '==', false);
  if (category) query = query.where('categoryLower', '==', category);

  const snap = await query.limit(limit).get();
  const items = snap.docs.map((d) => ({ id: d.id, ...stripInternal(d.data()) }));

  res.json({ ok: true, data: items });
});

/**
 * GET /api/affiliate/trending
 * Trending Brands section — top products by click count.
 */
export const trendingProducts = asyncHandler(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 10, 20);
  const snap = await db
    .collection('products')
    .where('approved', '==', true)
    .where('hidden', '==', false)
    .orderBy('clicks', 'desc')
    .limit(limit)
    .get();

  const items = snap.docs.map((d) => ({ id: d.id, ...stripInternal(d.data()) }));
  res.json({ ok: true, data: items });
});

const ClickBody = z.object({ productId: z.string().min(1) });

/**
 * POST /api/affiliate/click
 * Records an affiliate click (for admin analytics) and returns the destination URL.
 * The app opens the returned `websiteUrl`.
 */
export const trackClick = asyncHandler(async (req, res) => {
  const parsed = ClickBody.safeParse(req.body);
  if (!parsed.success) throw ApiError.badRequest('productId is required');

  const ref = db.collection('products').doc(parsed.data.productId);
  const snap = await ref.get();
  if (!snap.exists) throw ApiError.notFound('Product not found');

  const product = snap.data();
  if (!product.approved || product.hidden) {
    throw ApiError.forbidden('Product is not available');
  }

  // Atomic increment + lightweight click log for analytics.
  await ref.update({ clicks: admin.firestore.FieldValue.increment(1) });
  await db.collection('affiliateClicks').add({
    productId: ref.id,
    brandId: product.brandId || null,
    userId: req.user.uid,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  res.json({ ok: true, data: { websiteUrl: product.websiteUrl } });
});

/** Never leak internal moderation fields to the app. */
function stripInternal(data) {
  const { approved, hidden, categoryLower, ...rest } = data;
  return rest;
}

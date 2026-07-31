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
  // Two equality filters need no composite index; sort by clicks in memory
  // (product counts are small) so we don't require an ordered index.
  const snap = await db
    .collection('products')
    .where('approved', '==', true)
    .where('hidden', '==', false)
    .get();

  const items = snap.docs
    .map((d) => ({ id: d.id, ...d.data() }))
    .sort((a, b) => (b.clicks || 0) - (a.clicks || 0))
    .slice(0, limit)
    .map(({ approved, hidden, categoryLower, ...rest }) => rest);
  res.json({ ok: true, data: items });
});

/**
 * GET /api/affiliate/featured
 * The admin-chosen Featured Brand for the top of the Home screen (Module 4),
 * with its approved/visible products. Returns { data: null } when none is set.
 */
export const featuredBrand = asyncHandler(async (_req, res) => {
  const cfg = await db.collection('config').doc('home').get();
  const brandId = cfg.exists ? cfg.data().featuredBrandId : null;
  if (!brandId) return res.json({ ok: true, data: null });

  const [brandSnap, productsSnap] = await Promise.all([
    db.collection('brands').doc(brandId).get(),
    db
      .collection('products')
      .where('brandId', '==', brandId)
      .where('approved', '==', true)
      .where('hidden', '==', false)
      .limit(10)
      .get(),
  ]);

  const products = productsSnap.docs.map((d) => ({
    id: d.id,
    ...stripInternal(d.data()),
  }));
  // Nothing to show if the featured brand has no live products.
  if (products.length === 0) return res.json({ ok: true, data: null });

  res.json({
    ok: true,
    data: {
      brandId,
      brandName: brandSnap.exists ? brandSnap.data().name : products[0].brandName,
      products,
    },
  });
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

/* ─────────────── Brand submission (Module 4) ─────────────── */

const BrandBody = z.object({
  name: z.string().min(2).max(80),
  logoUrl: z.string().url().optional().or(z.literal('')),
  website: z.string().url().optional().or(z.literal('')),
});

/**
 * POST /api/affiliate/brands
 * A user submits a brand for admin review. Starts in `pending`; the admin
 * approves/rejects via the dashboard.
 */
export const submitBrand = asyncHandler(async (req, res) => {
  const parsed = BrandBody.safeParse(req.body);
  if (!parsed.success) throw ApiError.badRequest('A brand name is required');

  const ref = await db.collection('brands').add({
    name: parsed.data.name.trim(),
    logoUrl: parsed.data.logoUrl || null,
    website: parsed.data.website || null,
    ownerUid: req.user.uid,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  res.status(201).json({ ok: true, data: { id: ref.id, status: 'pending' } });
});

/** GET /api/affiliate/my-brands — the caller's own brand submissions. */
export const myBrands = asyncHandler(async (req, res) => {
  const snap = await db
    .collection('brands')
    .where('ownerUid', '==', req.user.uid)
    .get();
  const items = snap.docs
    .map((d) => ({ id: d.id, ...d.data() }))
    .sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));
  res.json({ ok: true, data: items });
});

const ProductBody = z.object({
  brandId: z.string().min(1),
  name: z.string().min(1).max(120),
  price: z.coerce.number().nonnegative(),
  description: z.string().max(500).optional().or(z.literal('')),
  imageUrl: z.string().url().optional().or(z.literal('')),
  websiteUrl: z.string().url(),
  category: z.string().min(1),
});

/**
 * POST /api/affiliate/products
 * The brand owner lists a product. Only allowed once their brand is approved.
 * Products start hidden=false but approved=false — an admin flips `approved`.
 */
export const submitProduct = asyncHandler(async (req, res) => {
  const parsed = ProductBody.safeParse(req.body);
  if (!parsed.success) throw ApiError.badRequest('Missing or invalid product fields');
  const p = parsed.data;

  const brandSnap = await db.collection('brands').doc(p.brandId).get();
  if (!brandSnap.exists) throw ApiError.notFound('Brand not found');
  const brand = brandSnap.data();
  if (brand.ownerUid !== req.user.uid) {
    throw ApiError.forbidden('You do not own this brand');
  }
  if (brand.status !== 'approved') {
    throw ApiError.forbidden('Your brand must be approved before listing products');
  }

  const ref = await db.collection('products').add({
    brandId: p.brandId,
    brandName: brand.name,
    name: p.name.trim(),
    price: p.price,
    description: p.description || '',
    imageUrl: p.imageUrl || '',
    websiteUrl: p.websiteUrl,
    category: p.category,
    categoryLower: p.category.toLowerCase(),
    approved: false,
    hidden: false,
    clicks: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  res.status(201).json({ ok: true, data: { id: ref.id, approved: false } });
});

/** Never leak internal moderation fields to the app. */
function stripInternal(data) {
  const { approved, hidden, categoryLower, ...rest } = data;
  return rest;
}

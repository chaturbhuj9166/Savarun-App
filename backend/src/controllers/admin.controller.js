import { z } from 'zod';
import { db, admin, firebaseAuth } from '../config/firebase.js';
import { ApiError } from '../utils/ApiError.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { getWeights, setWeights } from '../services/fitScore.service.js';

/* ─────────────── Analytics Dashboard ─────────────── */

/**
 * GET /api/admin/analytics
 * Total users, daily-active count, trending style categories, top affiliate products.
 */
export const getAnalytics = asyncHandler(async (_req, res) => {
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000);

  const [usersCount, dau, trendingStyles, topProducts] = await Promise.all([
    db.collection('users').count().get().then((s) => s.data().count),
    db
      .collection('users')
      .where('lastActiveAt', '>=', since)
      .count()
      .get()
      .then((s) => s.data().count)
      .catch(() => 0),
    computeTrendingStyles(),
    db
      .collection('products')
      .orderBy('clicks', 'desc')
      .limit(5)
      .get()
      .then((snap) => snap.docs.map((d) => ({ id: d.id, name: d.data().name, clicks: d.data().clicks || 0 }))),
  ]);

  res.json({
    ok: true,
    data: { totalUsers: usersCount, dailyActiveUsers: dau, trendingStyles, topProducts },
  });
});

/** Aggregate style categories from recent outfit analyses across all users. */
async function computeTrendingStyles() {
  const snap = await db.collectionGroup('outfitHistory').orderBy('createdAt', 'desc').limit(500).get();
  const counts = new Map();
  for (const doc of snap.docs) {
    for (const s of doc.data().styleDna || []) {
      if (!s.category) continue;
      counts.set(s.category, (counts.get(s.category) || 0) + (Number(s.percentage) || 0));
    }
  }
  return [...counts.entries()]
    .map(([category, weight]) => ({ category, weight }))
    .sort((a, b) => b.weight - a.weight)
    .slice(0, 8);
    
}

/* ─────────────── Listings for the dashboard ─────────────── */

/** GET /api/admin/users?limit=50 — all users with activity + moderation status. */
export const listUsers = asyncHandler(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 50, 200);
  const snap = await db.collection('users').limit(limit).get();
  const users = snap.docs.map((d) => {
    const u = d.data();
    return {
      uid: d.id,
      name: u.name || u.username || 'Savarun User',
      email: u.email || null,
      photoURL: u.photoURL || null,
      style: u.style || null,
      status: u.status || 'active',
      followers: u.followers || 0,
    };
  });
  res.json({ ok: true, data: users });
});

/** GET /api/admin/brands?status=pending — brand applications. */
export const listBrands = asyncHandler(async (req, res) => {
  const status = (req.query.status || '').toString().trim();
  let query = db.collection('brands');
  if (status) query = query.where('status', '==', status);
  const snap = await query.limit(200).get();
  const brands = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  res.json({ ok: true, data: brands });
});

/** GET /api/admin/products — every product, including hidden/unapproved. */
export const listAllProducts = asyncHandler(async (_req, res) => {
  const snap = await db.collection('products').limit(200).get();
  const products = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  res.json({ ok: true, data: products });
});

/** PATCH /api/admin/products/:id/approval  body: { approved: boolean } */
export const setProductApproval = asyncHandler(async (req, res) => {
  const approved = z.boolean().safeParse(req.body?.approved);
  if (!approved.success) throw ApiError.badRequest('approved (boolean) is required');
  const ref = db.collection('products').doc(req.params.id);
  const snap = await ref.get();
  if (!snap.exists) throw ApiError.notFound('Product not found');
  await ref.update({ approved: approved.data });
  res.json({ ok: true, data: { id: ref.id, approved: approved.data } });
});

/* ─────────────── Brand & Product Management ─────────────── */

/** POST /api/admin/brands/:id/decision  body: { decision: 'approve'|'reject', note? } */
const DecisionBody = z.object({
  decision: z.enum(['approve', 'reject']),
  note: z.string().optional(),
});

export const decideBrand = asyncHandler(async (req, res) => {
  const parsed = DecisionBody.safeParse(req.body);
  if (!parsed.success) throw ApiError.badRequest('decision must be "approve" or "reject"');

  const ref = db.collection('brands').doc(req.params.id);
  const snap = await ref.get();
  if (!snap.exists) throw ApiError.notFound('Brand not found');

  const status = parsed.data.decision === 'approve' ? 'approved' : 'rejected';
  await ref.update({
    status,
    reviewNote: parsed.data.note || null,
    reviewedBy: req.user.uid,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  res.json({ ok: true, data: { id: ref.id, status } });
});

/** PATCH /api/admin/products/:id/visibility  body: { hidden: boolean } */
export const setProductVisibility = asyncHandler(async (req, res) => {
  const hidden = z.boolean().safeParse(req.body?.hidden);
  if (!hidden.success) throw ApiError.badRequest('hidden (boolean) is required');

  const ref = db.collection('products').doc(req.params.id);
  const snap = await ref.get();
  if (!snap.exists) throw ApiError.notFound('Product not found');

  await ref.update({ hidden: hidden.data });
  res.json({ ok: true, data: { id: ref.id, hidden: hidden.data } });
});

/** PUT /api/admin/featured-brand  body: { brandId: string } */
export const setFeaturedBrand = asyncHandler(async (req, res) => {
  const brandId = z.string().min(1).safeParse(req.body?.brandId);
  if (!brandId.success) throw ApiError.badRequest('brandId is required');

  await db.collection('config').doc('home').set({ featuredBrandId: brandId.data }, { merge: true });
  res.json({ ok: true, data: { featuredBrandId: brandId.data } });
});

/* ─────────────── AI Trend Tuning ─────────────── */

/** GET /api/admin/fit-weights */
export const getFitWeights = asyncHandler(async (_req, res) => {
  res.json({ ok: true, data: await getWeights() });
});

/** PUT /api/admin/fit-weights  body: { trendMatch?, colorHarmony?, ... } */
export const updateFitWeights = asyncHandler(async (req, res) => {
  try {
    const updated = await setWeights(req.body || {});
    res.json({ ok: true, data: updated });
  } catch (err) {
    throw ApiError.badRequest(err.message);
  }
});

/* ─────────────── User Management ─────────────── */

/** POST /api/admin/users/:uid/moderate  body: { action: 'ban'|'suspend'|'verify'|'reinstate' } */
const ModerateBody = z.object({
  action: z.enum(['ban', 'suspend', 'verify', 'reinstate']),
});

export const moderateUser = asyncHandler(async (req, res) => {
  const parsed = ModerateBody.safeParse(req.body);
  if (!parsed.success) throw ApiError.badRequest('action must be ban|suspend|verify|reinstate');

  const { uid } = req.params;
  const { action } = parsed.data;

  // Reflect status in Firestore profile.
  const statusMap = { ban: 'banned', suspend: 'suspended', verify: 'verified', reinstate: 'active' };
  await db.collection('users').doc(uid).set(
    { status: statusMap[action], moderatedBy: req.user.uid, moderatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true }
  );

  // Banned/suspended users are disabled at the Auth level so tokens stop working.
  if (action === 'ban' || action === 'suspend') {
    await firebaseAuth.updateUser(uid, { disabled: true });
    await firebaseAuth.revokeRefreshTokens(uid);
  } else if (action === 'reinstate') {
    await firebaseAuth.updateUser(uid, { disabled: false });
  }

  res.json({ ok: true, data: { uid, status: statusMap[action] } });
});

/** POST /api/admin/users/:uid/set-admin  body: { admin: boolean } — grant/revoke dashboard access. */
export const setUserAdmin = asyncHandler(async (req, res) => {
  const isAdmin = z.boolean().safeParse(req.body?.admin);
  if (!isAdmin.success) throw ApiError.badRequest('admin (boolean) is required');

  await firebaseAuth.setCustomUserClaims(req.params.uid, { admin: isAdmin.data });
  res.json({ ok: true, data: { uid: req.params.uid, admin: isAdmin.data } });
});

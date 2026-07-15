import { db } from '../config/firebase.js';
import { asyncHandler } from '../utils/asyncHandler.js';

/**
 * GET /api/wardrobe/analytics
 * Wardrobe Analytics (Module 2): item count, color breakdown, gap alerts, least-worn.
 *
 * Reads the user's wardrobe items from Firestore:
 *   users/{uid}/wardrobe/{itemId}
 *   item = { category, colorName, colorHex, season, formality, wearCount, createdAt }
 */
export const getWardrobeAnalytics = asyncHandler(async (req, res) => {
  const snap = await db.collection('users').doc(req.user.uid).collection('wardrobe').get();
  const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

  const totalItems = items.length;

  // Most-used color breakdown.
  const colorCounts = tally(items, (i) => i.colorName || i.colorHex);
  const colorBreakdown = toSortedList(colorCounts).slice(0, 8);

  // Category counts (used for gap alerts).
  const categoryCounts = tally(items, (i) => normalizeCategory(i.category));

  // Gap alerts — simple rule set comparing what's missing/over-represented.
  const gapAlerts = buildGapAlerts(categoryCounts, items);

  // Least-worn items (lowest wearCount), highlight up to 5.
  const leastWorn = [...items]
    .sort((a, b) => (a.wearCount || 0) - (b.wearCount || 0))
    .slice(0, 5)
    .map((i) => ({ id: i.id, category: i.category, colorName: i.colorName, wearCount: i.wearCount || 0 }));

  res.json({
    ok: true,
    data: { totalItems, colorBreakdown, categoryCounts, gapAlerts, leastWorn },
  });
});

function tally(items, keyFn) {
  const map = new Map();
  for (const item of items) {
    const key = keyFn(item);
    if (!key) continue;
    map.set(key, (map.get(key) || 0) + 1);
  }
  return map;
}

function toSortedList(map) {
  return [...map.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count);
}

function normalizeCategory(category) {
  return (category || '').toString().trim().toLowerCase();
}

function buildGapAlerts(categoryCounts, items) {
  const alerts = [];
  const get = (c) => categoryCounts.get(c) || 0;

  const jeans = get('jeans');
  const formalTrousers = items.filter(
    (i) => /trouser|formal pant/i.test(i.category || '') || (i.formality === 'formal' && /bottom|pant|trouser/i.test(i.category || ''))
  ).length;
  if (jeans >= 3 && formalTrousers === 0) {
    alerts.push(`You have ${jeans} jeans but no formal trousers.`);
  }

  const footwear = get('shoes') + get('footwear') + get('sneakers');
  if (footwear === 0 && items.length > 0) {
    alerts.push('Your wardrobe has no footwear added yet.');
  }

  const outerwear = get('jacket') + get('outerwear') + get('coat');
  if (outerwear === 0 && items.length >= 5) {
    alerts.push('No outerwear yet — consider adding a jacket or coat.');
  }

  return alerts;
}

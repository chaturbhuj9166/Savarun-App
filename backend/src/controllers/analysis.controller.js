import { readFileSync } from 'node:fs';
import { db, admin } from '../config/firebase.js';
import { ApiError } from '../utils/ApiError.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { analyzeOutfitImage } from '../services/openaiVision.service.js';
import { getWeights, computeFitScore } from '../services/fitScore.service.js';
import { validateVisionResult, normalizeStyleDna } from '../services/analysisNormalizer.js';

/**
 * POST /api/analysis  (multipart, field "image")
 * The core feature: analyze an outfit photo and return Fit Score + Style DNA + feedback.
 */
export const analyzeOutfit = asyncHandler(async (req, res) => {
  if (!req.file) throw ApiError.badRequest('No image file provided (field "image")');
  const save = req.body?.save !== 'false';

  // Public URL to the stored image (for history/display).
  const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

  // The vision provider (Groq) can't reach our localhost URL, so we send the
  // image inline as a base64 data URL.
  const base64 = readFileSync(req.file.path).toString('base64');
  const dataUrl = `data:${req.file.mimetype || 'image/jpeg'};base64,${base64}`;

  // 1. Vision model detects the outfit + scores each factor.
  const raw = await analyzeOutfitImage(dataUrl);
  const vision = validateVisionResult(raw);

  // 2. Weighted Fit Score using current (possibly admin-tuned) weights.
  const weights = await getWeights();
  const { score, breakdown } = computeFitScore(vision.factorScores, weights);

  // 3. Clean Style DNA so percentages sum to 100.
  const styleDna = normalizeStyleDna(vision.styleDna);

  const result = {
    fitScore: score,
    breakdown,
    styleDna,
    detection: vision.detection,
    feedback: vision.feedback,
    imageUrl,
    createdAt: new Date().toISOString(),
  };

  // 4. Optionally save to the user's Outfit History (Module 1 → Screen 17).
  if (save) {
    const doc = await db
      .collection('users')
      .doc(req.user.uid)
      .collection('outfitHistory')
      .add({ ...result, createdAt: admin.firestore.FieldValue.serverTimestamp() });
    result.id = doc.id;
  }

  res.json({ ok: true, data: result });
});

/**
 * GET /api/analysis/history
 * Paginated Outfit History for the logged-in user.
 */
export const getHistory = asyncHandler(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 20, 50);

  const snap = await db
    .collection('users')
    .doc(req.user.uid)
    .collection('outfitHistory')
    .orderBy('createdAt', 'desc')
    .limit(limit)
    .get();

  const items = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  res.json({ ok: true, data: items });
});

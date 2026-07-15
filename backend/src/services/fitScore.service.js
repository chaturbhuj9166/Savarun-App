import { db } from '../config/firebase.js';

/**
 * Default Fit Score weights — exactly as defined in the spec (sum = 1.0).
 * Admins can override these from the dashboard ("AI Trend Tuning"); overrides
 * are stored in Firestore at config/fitScoreWeights.
 */
export const DEFAULT_WEIGHTS = Object.freeze({
  trendMatch: 0.3,
  colorHarmony: 0.2,
  styleConsistency: 0.2,
  silhouetteBalance: 0.15,
  accessories: 0.15,
});

export const FACTOR_KEYS = Object.keys(DEFAULT_WEIGHTS);

const WEIGHTS_DOC = db.collection('config').doc('fitScoreWeights');

/**
 * Read the current weights from Firestore, falling back to defaults.
 * Any missing factor falls back individually, and the result is normalised
 * so the weights always sum to 1.0 even after manual edits.
 */
export async function getWeights() {
  let stored = {};
  try {
    const snap = await WEIGHTS_DOC.get();
    if (snap.exists) stored = snap.data() || {};
  } catch {
    // If config can't be read, defaults are a safe fallback.
  }

  const merged = {};
  for (const key of FACTOR_KEYS) {
    const v = Number(stored[key]);
    merged[key] = Number.isFinite(v) && v >= 0 ? v : DEFAULT_WEIGHTS[key];
  }
  return normalise(merged);
}

/** Persist admin-tuned weights (called from the admin module). */
export async function setWeights(partial) {
  const current = await getWeights();
  const next = { ...current };
  for (const key of FACTOR_KEYS) {
    if (partial[key] !== undefined) {
      const v = Number(partial[key]);
      if (!Number.isFinite(v) || v < 0) {
        throw new Error(`Invalid weight for "${key}": must be a number >= 0`);
      }
      next[key] = v;
    }
  }
  const normalised = normalise(next);
  await WEIGHTS_DOC.set(normalised, { merge: true });
  return normalised;
}

function normalise(weights) {
  const total = FACTOR_KEYS.reduce((sum, k) => sum + weights[k], 0);
  if (total <= 0) return { ...DEFAULT_WEIGHTS };
  const out = {};
  for (const k of FACTOR_KEYS) out[k] = weights[k] / total;
  return out;
}

/**
 * Compute the final 0–100 Fit Score from the AI's per-factor sub-scores.
 *
 * @param {object} factorScores  e.g. { trendMatch: 80, colorHarmony: 65, ... } (each 0–100)
 * @param {object} weights       weights summing to 1.0
 * @returns {{ score: number, breakdown: Array<{factor,score,weight,contribution}> }}
 */
export function computeFitScore(factorScores, weights) {
  const breakdown = FACTOR_KEYS.map((factor) => {
    const raw = clamp(Number(factorScores?.[factor]) || 0, 0, 100);
    const weight = weights[factor];
    return {
      factor,
      score: Math.round(raw),
      weight: Math.round(weight * 100), // percentage for display
      contribution: Math.round(raw * weight * 10) / 10,
    };
  });

  const score = Math.round(breakdown.reduce((sum, b) => sum + b.score * (b.weight / 100), 0));
  return { score: clamp(score, 0, 100), breakdown };
}

function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

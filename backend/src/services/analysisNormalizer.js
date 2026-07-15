import { z } from 'zod';

/** Validate & coerce the raw model output into a trusted shape. */
const VisionSchema = z.object({
  detection: z.object({
    clothingTypes: z.array(z.string()).default([]),
    colorPalette: z
      .array(z.object({ name: z.string().default(''), hex: z.string().default('') }))
      .default([]),
    pattern: z.string().default('other'),
    fabric: z.array(z.string()).default([]),
    fitType: z.string().default('other'),
    accessories: z.array(z.string()).default([]),
  }),
  factorScores: z.object({
    trendMatch: z.coerce.number().default(0),
    colorHarmony: z.coerce.number().default(0),
    styleConsistency: z.coerce.number().default(0),
    silhouetteBalance: z.coerce.number().default(0),
    accessories: z.coerce.number().default(0),
  }),
  styleDna: z
    .array(z.object({ category: z.string(), percentage: z.coerce.number() }))
    .default([]),
  feedback: z.object({
    summary: z.string().default(''),
    suggestions: z
      .array(z.object({ type: z.string().default('keep'), text: z.string() }))
      .default([]),
  }),
});

export function validateVisionResult(raw) {
  return VisionSchema.parse(raw);
}

/** Ensure Style DNA percentages are clean integers that sum to 100. */
export function normalizeStyleDna(styleDna) {
  const cleaned = (styleDna || [])
    .filter((s) => s.category && Number.isFinite(Number(s.percentage)))
    .map((s) => ({ category: s.category.trim(), percentage: Math.max(0, Number(s.percentage)) }));

  const total = cleaned.reduce((sum, s) => sum + s.percentage, 0);
  if (total <= 0) return cleaned;

  // Rescale to 100 and round, fixing any drift on the largest bucket.
  const scaled = cleaned.map((s) => ({
    category: s.category,
    percentage: Math.round((s.percentage / total) * 100),
  }));
  const drift = 100 - scaled.reduce((sum, s) => sum + s.percentage, 0);
  if (drift !== 0 && scaled.length > 0) {
    const idx = scaled.reduce((maxI, s, i, arr) => (s.percentage > arr[maxI].percentage ? i : maxI), 0);
    scaled[idx].percentage += drift;
  }
  return scaled.sort((a, b) => b.percentage - a.percentage);
}

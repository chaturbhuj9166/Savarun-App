import { openai, VISION_MODEL, AI_PROVIDER } from '../config/openai.js';
import { ApiError } from '../utils/ApiError.js';

/**
 * The structured shape we ask GPT-4o to return. Keeping the contract explicit
 * in the prompt (plus JSON mode) keeps responses parseable and stable.
 */
const SYSTEM_PROMPT = `You are Savarun's AI Fashion Doctor — a professional stylist who examines an outfit photo and writes a short, confident "style report" like a doctor's diagnosis and prescription. You RATE the look and RECOMMEND improvements grounded in CURRENT fashion trends.

Respond with ONLY a JSON object in EXACTLY this shape:

{
  "detection": {
    "clothingTypes": ["string"],        // e.g. ["hoodie", "jeans", "sneakers"]
    "colorPalette": [{ "name": "string", "hex": "#RRGGBB" }],
    "pattern": "solid | striped | printed | checkered | other",
    "fabric": ["string"],               // e.g. ["denim", "cotton"]
    "fitType": "slim | regular | oversized | loose | other",
    "accessories": ["string"]           // [] if none
  },
  "factorScores": {
    "trendMatch": 0,                     // 0-100, how on-trend the outfit is right now
    "colorHarmony": 0,                   // 0-100, how well the colors work together
    "styleConsistency": 0,               // 0-100, how coherent the overall style is
    "silhouetteBalance": 0,              // 0-100, proportion/fit balance top-to-bottom
    "accessories": 0                     // 0-100, how well accessories complete the look
  },
  "styleDna": [
    { "category": "string", "percentage": 0 }   // must sum to 100, e.g. Streetwear 70, Minimalist 20, Athleisure 10
  ],
  "feedback": {
    "summary": "string",                 // the "diagnosis": 1-2 sentence confident verdict on the look
    "trend": "string",                   // 1-2 sentences on what's trending NOW and how this outfit fits it
    "suggestions": [
      { "type": "add | swap | keep", "text": "string" }   // the "prescription": specific, trend-aware moves — mention concrete pieces, colours, or styling
    ]
  }
}

Rules:
- Output valid JSON only, no markdown, no commentary.
- All factor scores are integers 0-100.
- styleDna percentages are integers that sum to exactly 100.
- Write suggestions like a stylist's prescription: concrete and trend-aware (e.g. "Swap the white sneakers for chunky dad-sneakers — they're big this season"). Include at least one "keep" for what already works.
- "trend" must reference real, current fashion directions relevant to THIS outfit's style.
- If the image has no recognisable outfit/person, set every factorScore to 0, put an explanation in feedback.summary, and set trend to "".`;

/**
 * Call GPT-4o Vision on an outfit image.
 * @param {string} imageUrl  A publicly fetchable URL (Firebase Storage download URL) or data: URL.
 * @returns {Promise<object>} parsed analysis (detection, factorScores, styleDna, feedback)
 */
export async function analyzeOutfitImage(imageUrl) {
  let completion;
  try {
    completion = await openai.chat.completions.create({
      model: VISION_MODEL,
      temperature: 0.4,
      max_tokens: 2000,
      // Force a JSON-only reply. Groq's vision model is a reasoning model whose
      // thinking tokens count against max_tokens — leaving it on truncates the
      // answer and Groq rejects it with "Failed to validate JSON". Turning
      // reasoning off keeps the response short and strictly parseable.
      response_format: { type: 'json_object' },
      ...(AI_PROVIDER === 'groq'
        ? { reasoning_effort: 'none', reasoning_format: 'hidden' }
        : {}),
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Analyze this outfit and return ONLY the JSON object.' },
            { type: 'image_url', image_url: { url: imageUrl } },
          ],
        },
      ],
    });
  } catch (err) {
    throw new ApiError(502, `Vision model request failed: ${err.message}`);
  }

  const raw = completion.choices?.[0]?.message?.content;
  if (!raw) throw new ApiError(502, 'Vision model returned an empty response');

  const parsed = extractJson(raw);
  if (!parsed) throw new ApiError(502, 'Vision model returned invalid JSON');
  return parsed;
}

const TAG_PROMPT = `You are Savarun's wardrobe cataloguer. You receive a photo of a SINGLE clothing item and return strict JSON describing it. Respond with ONLY this object:

{
  "name": "string",          // short human name, e.g. "Black Oversized Hoodie"
  "category": "Tops | Bottoms | Footwear | Outerwear | Accessories",
  "colorName": "string",     // dominant colour name, e.g. "Black"
  "colorHex": "#RRGGBB",     // dominant colour hex
  "fabric": "Cotton | Denim | Linen | Silk | Wool | Polyester | Leather | Other",
  "season": "Summer | Winter | All-season",
  "formality": "Casual | Smart Casual | Formal"
}

Pick the single best value for each field. Output valid JSON only, no prose.`;

/**
 * Auto-tag a single wardrobe item photo (Module 2). Returns the same fields
 * the Add-Item form uses, so the app can pre-fill them.
 */
export async function tagClothingImage(imageUrl) {
  let completion;
  try {
    completion = await openai.chat.completions.create({
      model: VISION_MODEL,
      temperature: 0.2,
      max_tokens: 600,
      response_format: { type: 'json_object' },
      ...(AI_PROVIDER === 'groq'
        ? { reasoning_effort: 'none', reasoning_format: 'hidden' }
        : {}),
      messages: [
        { role: 'system', content: TAG_PROMPT },
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Tag this clothing item. Return ONLY the JSON.' },
            { type: 'image_url', image_url: { url: imageUrl } },
          ],
        },
      ],
    });
  } catch (err) {
    throw new ApiError(502, `Vision model request failed: ${err.message}`);
  }

  const raw = completion.choices?.[0]?.message?.content;
  if (!raw) throw new ApiError(502, 'Vision model returned an empty response');
  const parsed = extractJson(raw);
  if (!parsed) throw new ApiError(502, 'Vision model returned invalid JSON');
  return parsed;
}

/** Pull a JSON object out of a model response (handles ```json fences / prose). */
function extractJson(raw) {
  // Reasoning models can prefix a <think>...</think> trace. Drop it before
  // looking for the JSON body, otherwise braces inside it confuse the scan.
  const text = raw.replace(/<think>[\s\S]*?<\/think>/gi, '').trim();

  // Try direct parse first.
  try {
    return JSON.parse(text);
  } catch {
    // Fall through to extraction.
  }
  // Strip markdown code fences if present.
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fenced) {
    try {
      return JSON.parse(fenced[1]);
    } catch {
      // continue
    }
  }
  // Grab the outermost { ... } block.
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start !== -1 && end > start) {
    try {
      return JSON.parse(text.slice(start, end + 1));
    } catch {
      // give up
    }
  }
  return null;
}

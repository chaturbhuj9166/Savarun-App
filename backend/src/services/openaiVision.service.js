import { openai, VISION_MODEL, AI_PROVIDER } from '../config/openai.js';
import { ApiError } from '../utils/ApiError.js';

/**
 * The structured shape we ask GPT-4o to return. Keeping the contract explicit
 * in the prompt (plus JSON mode) keeps responses parseable and stable.
 */
const SYSTEM_PROMPT = `You are Savarun's expert AI fashion analyst. You receive a single photo of a person's outfit and return a strict JSON analysis.

Detect what the person is wearing and judge it like a professional stylist. Respond with ONLY a JSON object in EXACTLY this shape:

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
    "summary": "string",                 // 1-2 sentence overall verdict
    "suggestions": [
      { "type": "add | swap | keep", "text": "string" }   // actionable, specific
    ]
  }
}

Rules:
- Output valid JSON only, no markdown, no commentary.
- All factor scores are integers 0-100.
- styleDna percentages are integers that sum to exactly 100.
- If the image has no recognisable outfit/person, set every factorScore to 0 and put an explanation in feedback.summary.`;

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

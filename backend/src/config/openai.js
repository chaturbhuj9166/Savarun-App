import OpenAI from 'openai';
import { env } from './env.js';

/**
 * Single shared vision client. Groq is OpenAI-compatible, so the same SDK
 * works — we just point it at Groq's base URL. The API key lives ONLY here
 * on the server and must never reach the Flutter app.
 */
const cfg = env.ai.provider === 'openai' ? env.ai.openai : env.ai.groq;

export const openai = new OpenAI({
  apiKey: cfg.apiKey || 'MISSING_API_KEY',
  baseURL: cfg.baseUrl,
});

export const VISION_MODEL = cfg.visionModel;
export const AI_PROVIDER = env.ai.provider;

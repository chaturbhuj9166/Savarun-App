import dotenv from 'dotenv';

dotenv.config();

/**
 * Centralised, validated environment config.
 * Anything required-but-missing fails fast at boot instead of mid-request.
 */
function required(name) {
  const value = process.env[name];
  if (!value || value.trim() === '') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

function optional(name, fallback = '') {
  const value = process.env[name];
  return value && value.trim() !== '' ? value.trim() : fallback;
}

export const env = {
  nodeEnv: optional('NODE_ENV', 'development'),
  port: Number(optional('PORT', '4000')),

  corsOrigins: optional('CORS_ORIGINS', '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean),

  firebase: {
    // Two ways to supply the service account:
    //   1. FIREBASE_SERVICE_ACCOUNT_JSON — the whole JSON pasted in one env
    //      var. Required on hosts with no writable repo files (Render, etc.).
    //   2. FIREBASE_SERVICE_ACCOUNT_PATH — a file path, convenient locally.
    // Neither is `required()` here so the check can produce a clearer error.
    serviceAccountJson: optional('FIREBASE_SERVICE_ACCOUNT_JSON'),
    serviceAccountPath: optional('FIREBASE_SERVICE_ACCOUNT_PATH'),
    projectId: optional('FIREBASE_PROJECT_ID'),
    storageBucket: optional('FIREBASE_STORAGE_BUCKET'),
  },

  /// Public origin of this server, e.g. https://savarun-api.onrender.com.
  /// Used to build absolute URLs for uploaded images. Falls back to the
  /// request's own host when unset.
  publicUrl: optional('PUBLIC_URL').replace(/\/+$/, ''),

  // AI vision provider. Groq is OpenAI-compatible, so we reuse the OpenAI SDK
  // with a different base URL. Switch provider via AI_PROVIDER (groq | openai).
  ai: {
    provider: optional('AI_PROVIDER', 'groq'),
    groq: {
      apiKey: optional('GROQ_API_KEY'),
      baseUrl: 'https://api.groq.com/openai/v1',
      visionModel: optional('GROQ_VISION_MODEL', 'qwen/qwen3.6-27b'),
    },
    openai: {
      apiKey: optional('OPENAI_API_KEY'),
      baseUrl: undefined, // SDK default
      visionModel: optional('OPENAI_VISION_MODEL', 'gpt-4o'),
    },
  },
};

export const isProd = env.nodeEnv === 'production';

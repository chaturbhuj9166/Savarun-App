import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import { env, isProd } from './config/env.js';
import { apiLimiter } from './middleware/rateLimit.js';
import { notFoundHandler, errorHandler } from './middleware/errorHandler.js';
import { UPLOAD_DIR } from './middleware/upload.js';
import apiRoutes from './routes/index.js';

export function createApp() {
  const app = express();

  // Allow images to be embedded cross-origin (the Flutter app loads them).
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(compression());

  // CORS first, so it also applies to the static /uploads responses.
  // In development the Flutter web app runs on a random localhost port, so we
  // allow all origins; in production we use the configured allowlist.
  app.use(
    cors({
      origin: isProd && env.corsOrigins.length ? env.corsOrigins : true,
      credentials: true,
    })
  );

  app.use(express.json({ limit: '1mb' }));
  app.use(morgan(isProd ? 'combined' : 'dev'));

  // Serve uploaded images statically at /uploads/<filename>.
  app.use('/uploads', express.static(UPLOAD_DIR));

  // Health check (no auth) — handy for uptime monitors & load balancers.
  app.get('/health', (_req, res) => res.json({ ok: true, uptime: process.uptime() }));

  // All API endpoints live under /api and share the general rate limiter.
  app.use('/api', apiLimiter, apiRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

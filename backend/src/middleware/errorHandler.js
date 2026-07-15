import { isProd } from '../config/env.js';
import { ApiError } from '../utils/ApiError.js';

/** 404 handler for unknown routes. */
export const notFoundHandler = (req, res) => {
  res.status(404).json({
    ok: false,
    error: `Route not found: ${req.method} ${req.originalUrl}`,
  });
};

/** Central error middleware — all thrown errors land here. */
// eslint-disable-next-line no-unused-vars
export const errorHandler = (err, req, res, _next) => {
  const isApiError = err instanceof ApiError;
  const statusCode = isApiError ? err.statusCode : 500;

  if (!isApiError || statusCode >= 500) {
    // Unexpected — log full stack for debugging.
    console.error('[ERROR]', err);
  }

  res.status(statusCode).json({
    ok: false,
    error: isApiError ? err.message : 'Internal server error',
    ...(err.details ? { details: err.details } : {}),
    ...(!isProd && !isApiError ? { stack: err.stack } : {}),
  });
};

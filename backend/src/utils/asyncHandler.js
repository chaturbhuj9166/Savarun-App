/**
 * Wrap async route handlers so thrown errors / rejected promises
 * automatically flow to the Express error middleware.
 */
export const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

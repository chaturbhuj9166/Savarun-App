import { ApiError } from '../utils/ApiError.js';

/**
 * Gate for admin-dashboard endpoints.
 * Requires `requireAuth` to have run first (so req.user exists).
 *
 * The `admin` custom claim is set with:
 *   admin.auth().setCustomUserClaims(uid, { admin: true })
 */
export const adminOnly = (req, _res, next) => {
  if (!req.user?.isAdmin) {
    throw ApiError.forbidden('Admin access required');
  }
  next();
};

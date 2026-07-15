import { firebaseAuth } from "../config/firebase.js";
import { ApiError } from "../utils/ApiError.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { isProd } from "../config/env.js";

export const requireAuth = asyncHandler(async (req, _res, next) => {
  const header = req.headers.authorization || "";
  const [scheme, token] = header.split(" ");

  if (scheme !== "Bearer" || !token) {
    throw ApiError.unauthorized("Missing or malformed Authorization header");
  }

  let decoded;

  try {
    decoded = await firebaseAuth.verifyIdToken(token);
  } catch (err) {
    // Log the real reason server-side; surface it in dev to speed debugging.
    console.error("[auth] verifyIdToken failed:", err.code, "-", err.message);
    throw ApiError.unauthorized(
      isProd ? "Invalid or expired token" : `Token verification failed: ${err.message}`
    );
  }

  req.user = {
    uid: decoded.uid,
    email: decoded.email || null,
    name: decoded.name || null,
    photoURL: decoded.picture || null,
    phoneNumber: decoded.phone_number || null,
    provider: decoded.firebase?.sign_in_provider || null,
    isAdmin: decoded.admin === true,
  };

  next();
});
import { asyncHandler } from "../utils/asyncHandler.js";
import * as authService from "../services/auth.service.js";

/**
 * POST /api/auth/login
 * Body:
 * {
 *   "idToken": "firebase-id-token"
 * }
 */
export const login = asyncHandler(async (req, res) => {
  const { idToken } = req.body;

  const user = await authService.login(idToken);

  res.status(200).json({
    success: true,
    message: "Login successful",
    data: user,
  });
});

/**
 * GET /api/auth/me
 * Header:
 * Authorization: Bearer <firebase_token>
 */
export const me = asyncHandler(async (req, res) => {
  const user = await authService.getCurrentUser(req.user.uid);

  res.status(200).json({
    success: true,
    data: user,
  });
});
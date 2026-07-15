import { Router } from "express";
import { login, me } from "../controllers/auth.controller.js";
import { requireAuth } from "../middleware/auth.js";

const router = Router();

// Login (Google / Phone OTP / Apple)
// Flutter Firebase ID Token bhejega
router.post("/login", login);

// Current logged-in user
router.get("/me", requireAuth, me);

export default router;
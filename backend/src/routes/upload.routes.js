import { Router } from "express";
import { requireAuth } from "../middleware/auth.js";
import { uploadImage } from "../middleware/upload.js";
import { uploadSingle, uploadMultiple } from "../controllers/upload.controller.js";

const router = Router();

// All uploads require a valid Firebase ID token.
router.post("/", requireAuth, uploadImage.single("image"), uploadSingle);
router.post("/bulk", requireAuth, uploadImage.array("images", 20), uploadMultiple);

export default router;

import { existsSync, mkdirSync } from "node:fs";
import { resolve, extname } from "node:path";
import multer from "multer";
import { ApiError } from "../utils/ApiError.js";

/**
 * Local image storage — a stand-in for Firebase Storage while the client
 * is on the Spark plan (Cloud Storage needs Blaze). Files land in the
 * backend's `uploads/` folder and are served statically at `/uploads/...`.
 *
 * TODO(storage): swap this for Firebase Storage once Blaze is enabled.
 */
export const UPLOAD_DIR = resolve(process.cwd(), "uploads");

if (!existsSync(UPLOAD_DIR)) {
  mkdirSync(UPLOAD_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    // <uid>-<timestamp>-<rand>.<ext>  → unique & traceable to a user
    const uid = req.user?.uid || "anon";
    const rand = Math.round(Math.random() * 1e9);
    const ext = extname(file.originalname).toLowerCase() || ".jpg";
    cb(null, `${uid}-${Date.now()}-${rand}${ext}`);
  },
});

const ALLOWED_MIME = new Set([
  "image/jpeg", "image/png", "image/webp", "image/heic", "image/heif",
]);
const ALLOWED_EXT = new Set([".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif"]);

function fileFilter(_req, file, cb) {
  // Web multipart uploads often arrive as application/octet-stream, so we
  // also accept known image file extensions.
  const ext = extname(file.originalname).toLowerCase();
  if (ALLOWED_MIME.has(file.mimetype) || ALLOWED_EXT.has(ext)) {
    return cb(null, true);
  }
  cb(ApiError.badRequest(`Unsupported file type: ${file.mimetype} (${ext || "no ext"})`));
}

export const uploadImage = multer({
  storage,
  fileFilter,
  limits: { fileSize: 8 * 1024 * 1024 }, // 8 MB per image
});

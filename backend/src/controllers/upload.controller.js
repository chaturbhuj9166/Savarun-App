import { ApiError } from "../utils/ApiError.js";
import { env } from "../config/env.js";

/**
 * Build the public URL the app uses to fetch an uploaded file. PUBLIC_URL
 * pins the canonical https origin behind a proxy; otherwise use the request.
 */
function publicUrl(req, filename) {
  const origin = env.publicUrl || `${req.protocol}://${req.get("host")}`;
  return `${origin}/uploads/${filename}`;
}

/** POST /api/uploads — single image (field name: "image"). */
export function uploadSingle(req, res) {
  if (!req.file) throw ApiError.badRequest("No image file provided");
  res.status(201).json({
    ok: true,
    url: publicUrl(req, req.file.filename),
    filename: req.file.filename,
    size: req.file.size,
  });
}

/** POST /api/uploads/bulk — multiple images (field name: "images"). */
export function uploadMultiple(req, res) {
  if (!req.files || req.files.length === 0) {
    throw ApiError.badRequest("No image files provided");
  }
  res.status(201).json({
    ok: true,
    files: req.files.map((f) => ({
      url: publicUrl(req, f.filename),
      filename: f.filename,
      size: f.size,
    })),
  });
}

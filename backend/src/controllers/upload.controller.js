import { ApiError } from "../utils/ApiError.js";

/** Build the public URL the app uses to fetch an uploaded file. */
function publicUrl(req, filename) {
  return `${req.protocol}://${req.get("host")}/uploads/${filename}`;
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

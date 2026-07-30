import { ApiError } from "../utils/ApiError.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { storeUpload, isAbsolute } from "../services/storage.service.js";

/**
 * With the local driver, storeUpload may return a relative "/uploads/…" URL
 * when PUBLIC_URL is unset; make it absolute using the request host so the app
 * can fetch it. The firebase driver always returns an absolute URL.
 */
function absolutize(req, url) {
  if (isAbsolute(url)) return url;
  return `${req.protocol}://${req.get("host")}${url}`;
}

/** POST /api/uploads — single image (field name: "image"). */
export const uploadSingle = asyncHandler(async (req, res) => {
  if (!req.file) throw ApiError.badRequest("No image file provided");
  const url = absolutize(req, await storeUpload(req.file));
  res.status(201).json({
    ok: true,
    url,
    filename: req.file.filename,
    size: req.file.size,
  });
});

/** POST /api/uploads/bulk — multiple images (field name: "images"). */
export const uploadMultiple = asyncHandler(async (req, res) => {
  if (!req.files || req.files.length === 0) {
    throw ApiError.badRequest("No image files provided");
  }
  const files = await Promise.all(
    req.files.map(async (f) => ({
      url: absolutize(req, await storeUpload(f)),
      filename: f.filename,
      size: f.size,
    }))
  );
  res.status(201).json({ ok: true, files });
});

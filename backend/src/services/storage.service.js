import { randomUUID } from 'node:crypto';
import { readFile, unlink } from 'node:fs/promises';
import { basename } from 'node:path';

import { admin } from '../config/firebase.js';
import { env } from '../config/env.js';

/**
 * Where uploaded images live. Two drivers:
 *   - "local"    → served from this server's /uploads (dev / no-Blaze).
 *   - "firebase" → Firebase Storage (permanent, survives redeploys).
 *
 * Controllers call storeUpload(file) after multer has written the temp file to
 * disk; it returns the public URL to save in Firestore.
 */
const DRIVER = env.storage.driver;

let _bucket;
function bucket() {
  if (!_bucket) {
    const name = env.firebase.storageBucket;
    if (!name) {
      throw new Error(
        'STORAGE_DRIVER=firebase but FIREBASE_STORAGE_BUCKET is not set. ' +
          'Copy the bucket name from Firebase Console → Storage (e.g. ' +
          'savarun-app-b775b.firebasestorage.app).'
      );
    }
    _bucket = admin.storage().bucket(name);
  }
  return _bucket;
}

/**
 * Persist a multer temp file and return its public URL.
 * @param {{path:string, filename:string, mimetype?:string}} file
 * @param {string} [folder]  logical folder in the bucket, e.g. "outfits".
 */
export async function storeUpload(file, folder = 'uploads') {
  if (DRIVER === 'firebase') {
    return uploadToFirebase(file, folder);
  }
  // local: the file already sits in /uploads, served statically.
  const origin = env.publicUrl || '';
  return `${origin}/uploads/${file.filename}`;
}

async function uploadToFirebase(file, folder) {
  const data = await readFile(file.path);
  const objectPath = `${folder}/${file.filename}`;
  const token = randomUUID();

  await bucket().file(objectPath).save(data, {
    resumable: false,
    contentType: file.mimetype || 'image/jpeg',
    metadata: {
      // A download token makes the object readable via a stable URL without
      // making the whole bucket public.
      metadata: { firebaseStorageDownloadTokens: token },
    },
  });

  // Remove the local temp copy now that it's in the cloud.
  await unlink(file.path).catch(() => {});

  const encoded = encodeURIComponent(objectPath);
  return (
    `https://firebasestorage.googleapis.com/v0/b/${bucket().name}` +
    `/o/${encoded}?alt=media&token=${token}`
  );
}

/** For local driver the URL may be relative if PUBLIC_URL is unset; the
 *  controllers fall back to the request host in that case. */
export function isAbsolute(url) {
  return /^https?:\/\//i.test(url);
}

export { basename };

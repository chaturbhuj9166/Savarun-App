import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import admin from 'firebase-admin';
import { env } from './env.js';

/**
 * Initialise the Firebase Admin SDK once for the whole process.
 * This gives the server:
 *   - auth().verifyIdToken()  → trust requests coming from the Flutter app
 *   - firestore()             → read/write the same DB the app uses
 *   - storage()               → access outfit/clothing images if needed
 */
const serviceAccount = loadServiceAccount();

/**
 * Prefer the inline JSON env var (works on hosts like Render where the key
 * file is never committed), and fall back to a local file for development.
 */
function loadServiceAccount() {
  const { serviceAccountJson, serviceAccountPath } = env.firebase;

  if (serviceAccountJson) {
    try {
      const parsed = JSON.parse(serviceAccountJson);
      // Env vars often arrive with the newlines in private_key escaped.
      if (typeof parsed.private_key === 'string') {
        parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
      }
      return parsed;
    } catch (err) {
      throw new Error(
        `FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON. Paste the whole ` +
          `service-account file as a single line. (${err.message})`
      );
    }
  }

  if (serviceAccountPath) {
    try {
      return JSON.parse(
        readFileSync(resolve(process.cwd(), serviceAccountPath), 'utf-8')
      );
    } catch (err) {
      throw new Error(
        `Could not read Firebase service account at "${serviceAccountPath}". ` +
          `Download it from Firebase Console → Project Settings → Service ` +
          `Accounts. (${err.message})`
      );
    }
  }

  throw new Error(
    'No Firebase credentials configured. Set FIREBASE_SERVICE_ACCOUNT_JSON ' +
      '(recommended for hosting) or FIREBASE_SERVICE_ACCOUNT_PATH (local dev).'
  );
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: env.firebase.projectId || serviceAccount.project_id,
  storageBucket: env.firebase.storageBucket || undefined,
});

export const firebaseAuth = admin.auth();
export const db = admin.firestore();
export const storage = admin.storage();
export { admin };

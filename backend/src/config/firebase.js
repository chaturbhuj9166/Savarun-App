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
let serviceAccount;
try {
  const path = resolve(process.cwd(), env.firebase.serviceAccountPath);
  serviceAccount = JSON.parse(readFileSync(path, 'utf-8'));
} catch (err) {
  throw new Error(
    `Could not read Firebase service account at "${env.firebase.serviceAccountPath}". ` +
      `Download it from Firebase Console → Project Settings → Service Accounts. (${err.message})`
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

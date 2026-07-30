/**
 * Firestore rules tests for the chat request flow, run against the emulator.
 *
 *   npm install && npm test        (from app/rules-test)
 *
 * Covers the paths the app actually takes: send request, accept, decline,
 * message, and the reads/writes an outsider must never be allowed.
 */
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  addDoc,
  collection,
  getDocs,
  serverTimestamp,
} from 'firebase/firestore';

const ALICE = 'alice';
const BOB = 'bob';
const MALLORY = 'mallory';
const CHAT = `${ALICE}_${BOB}`; // ids sorted, same as ChatRepository.chatIdFor

const testEnv = await initializeTestEnvironment({
  projectId: 'savarun-rules-test',
  firestore: {
    // Run from the app/ directory (see rules-test/package.json).
    rules: readFileSync('firestore.rules', 'utf8'),
    host: '127.0.0.1',
    port: 8080,
  },
});

const results = [];
async function check(name, fn) {
  try {
    await fn();
    results.push(['PASS', name]);
  } catch (err) {
    results.push(['FAIL', `${name} — ${err.message.split('\n')[0]}`]);
  }
}

const as = (uid) => testEnv.authenticatedContext(uid).firestore();
const chatRef = (db) => doc(db, 'chats', CHAT);

// ── 1. Reading a thread that does not exist yet ──
// The app watches this doc before any request is sent.
await check('reading a non-existent thread is allowed', async () => {
  await assertSucceeds(getDoc(chatRef(as(ALICE))));
});

// ── 2. Sending a chat request ──
await check('alice can open a pending request with bob', async () => {
  await assertSucceeds(
    setDoc(chatRef(as(ALICE)), {
      participants: [ALICE, BOB],
      status: 'pending',
      requestedBy: ALICE,
      lastMessage: '',
      lastTime: serverTimestamp(),
    })
  );
});

await check('an outsider cannot read that thread', async () => {
  await assertFails(getDoc(chatRef(as(MALLORY))));
});

await check('an outsider cannot create a thread they are not in', async () => {
  await assertFails(
    setDoc(doc(as(MALLORY), 'chats', `${ALICE}_${MALLORY}x`), {
      participants: [ALICE, BOB],
      status: 'pending',
    })
  );
});

// ── 3. Accepting ──
await check('bob can accept the request', async () => {
  await assertSucceeds(updateDoc(chatRef(as(BOB)), { status: 'accepted' }));
});

await check('an outsider cannot accept it', async () => {
  await assertFails(updateDoc(chatRef(as(MALLORY)), { status: 'accepted' }));
});

// ── 4. Messaging ──
const msgs = (db) => collection(db, 'chats', CHAT, 'messages');

await check('bob can send a text message', async () => {
  await assertSucceeds(
    addDoc(msgs(as(BOB)), {
      senderId: BOB,
      text: 'hey',
      createdAt: serverTimestamp(),
    })
  );
});

await check('alice can send an outfit photo', async () => {
  await assertSucceeds(
    addDoc(msgs(as(ALICE)), {
      senderId: ALICE,
      text: '',
      imageUrl: 'https://example.com/outfit.jpg',
      createdAt: serverTimestamp(),
    })
  );
});

await check('nobody can send a message as someone else', async () => {
  await assertFails(
    addDoc(msgs(as(BOB)), { senderId: ALICE, text: 'spoofed' })
  );
});

await check('an outsider cannot read the messages', async () => {
  await assertFails(getDocs(msgs(as(MALLORY))));
});

await check('both participants can read the messages', async () => {
  await assertSucceeds(getDocs(msgs(as(ALICE))));
  await assertSucceeds(getDocs(msgs(as(BOB))));
});

// ── 5. Declining (deletes the thread so it can be re-sent) ──
await check('an outsider cannot delete the thread', async () => {
  await assertFails(deleteDoc(chatRef(as(MALLORY))));
});

await check('bob can decline (delete) the thread', async () => {
  await assertSucceeds(deleteDoc(chatRef(as(BOB))));
});

await check('alice can re-send the request afterwards', async () => {
  await assertSucceeds(
    setDoc(chatRef(as(ALICE)), {
      participants: [ALICE, BOB],
      status: 'pending',
      requestedBy: ALICE,
      lastTime: serverTimestamp(),
    })
  );
});

await testEnv.cleanup();

for (const [status, name] of results) {
  console.log(`${status === 'PASS' ? '  ok  ' : ' FAIL '} ${name}`);
}
const failed = results.filter(([s]) => s === 'FAIL').length;
console.log(`\n${results.length - failed}/${results.length} passed`);
process.exit(failed ? 1 : 0);

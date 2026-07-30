# Firestore rules tests

Runs `app/firestore.rules` against the Firestore emulator and asserts what each
role can and cannot do — currently the chat request flow (send / accept /
decline / message) and the reads an outsider must never get.

```bash
cd app/rules-test
npm install
npm test
```

Notes:

- `firebase-tools` is pinned to **13.x** because 14+ requires JDK 21 and the
  dev machine has JDK 17. The pinned copy is local to this folder, so it does
  not affect the globally installed CLI.
- The emulator config lives at `app/firebase.emulator.json`; the emulator
  refuses to load a rules file from outside its project directory, which is
  why the test runs from `app/`.
- The `PERMISSION_DENIED` lines in the output are expected — they are the
  `assertFails` cases proving the rules reject unauthorised access.

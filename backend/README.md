# Savarun Backend (Node + Express)

Node/Express API for the **business-logic + secret-holding** parts of Savarun.
Firebase handles Auth, Firestore, Realtime DB (chat) and Storage directly from the
Flutter app — this server handles everything that can't or shouldn't live on-device.

## What this backend owns

| Module | Why it's here |
|--------|---------------|
| **AI Outfit Analyzer** | The OpenAI API key must never ship in the app. All GPT-4o Vision calls + Fit Score math happen here. |
| **Affiliate** | Click tracking & analytics aggregation. |
| **Admin** | Brand approval, product visibility, AI weight tuning, user moderation, analytics. |
| **Wardrobe analytics** | Gap alerts / least-worn computation. |

Auth, Firestore CRUD for wardrobe/profiles, chat and image storage stay **Firebase-direct** from Flutter.

## How auth works

1. App logs in via Firebase Auth (Google / Apple / Phone OTP).
2. App gets an ID token: `await FirebaseAuth.instance.currentUser!.getIdToken()`.
3. App calls this API with header `Authorization: Bearer <token>`.
4. `requireAuth` verifies the token with the Firebase Admin SDK and sets `req.user`.
5. Admin routes additionally require the `admin` custom claim (set via `POST /api/admin/users/:uid/set-admin`).

## Setup

```bash
cd backend
npm install
cp .env.example .env        # then fill in values
# Put your Firebase service account JSON at the path set in FIREBASE_SERVICE_ACCOUNT_PATH
npm run dev                 # http://localhost:4000
```

Required env: `OPENAI_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_PATH`. See `.env.example`.

## API surface

```
GET    /health
GET    /api

# AI Outfit Analyzer  (auth)
POST   /api/analysis              { imageUrl, save? }  → fitScore, breakdown, styleDna, detection, feedback
GET    /api/analysis/history      ?limit=20

# Wardrobe  (auth)
GET    /api/wardrobe/analytics    → totalItems, colorBreakdown, gapAlerts, leastWorn

# Affiliate  (auth)
GET    /api/affiliate/products    ?category=&limit=
GET    /api/affiliate/trending    ?limit=
POST   /api/affiliate/click       { productId }        → { websiteUrl }

# Admin  (auth + admin claim)
GET    /api/admin/analytics
POST   /api/admin/brands/:id/decision        { decision: 'approve'|'reject', note? }
PATCH  /api/admin/products/:id/visibility     { hidden: boolean }
PUT    /api/admin/featured-brand              { brandId }
GET    /api/admin/fit-weights
PUT    /api/admin/fit-weights                 { trendMatch?, colorHarmony?, ... }
POST   /api/admin/users/:uid/moderate         { action: 'ban'|'suspend'|'verify'|'reinstate' }
POST   /api/admin/users/:uid/set-admin        { admin: boolean }
```

See [`DATA_MODEL.md`](./DATA_MODEL.md) for the Firestore collections this server reads/writes.

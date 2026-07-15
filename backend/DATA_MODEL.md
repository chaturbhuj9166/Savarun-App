# Firestore Data Model

Collections the backend reads/writes. The Flutter app shares this same database
(Firebase-direct for most CRUD); the server only touches what's listed here.

## `users/{uid}`
```
{
  username, bio, photoUrl,
  stylePreferences: ["Streetwear", ...],
  wardrobePublic: bool,
  status: "active" | "banned" | "suspended" | "verified",   // set by admin
  lastActiveAt: timestamp,        // used for Daily Active Users
  followersCount, followingCount
}
```

### `users/{uid}/wardrobe/{itemId}`
```
{
  category, colorName, colorHex,
  fabric, season, formality,      // AI auto-tagged (Module 2)
  imageUrl, wearCount: number, createdAt
}
```

### `users/{uid}/outfitHistory/{analysisId}`  ← written by `POST /api/analysis`
```
{
  fitScore, breakdown: [{factor, score, weight, contribution}],
  styleDna: [{category, percentage}],
  detection: { clothingTypes, colorPalette, pattern, fabric, fitType, accessories },
  feedback: { summary, suggestions: [{type, text}] },
  imageUrl, createdAt
}
```

## `brands/{brandId}`
```
{
  name, logoUrl, ownerUid,
  status: "pending" | "approved" | "rejected",   // set by admin
  reviewNote, reviewedBy, reviewedAt
}
```

## `products/{productId}`
```
{
  brandId, brandName, name, price, description,
  imageUrl, websiteUrl,
  category, categoryLower,        // categoryLower used for filtering
  approved: bool, hidden: bool,
  clicks: number, createdAt
}
```

## `affiliateClicks/{autoId}`  ← written by `POST /api/affiliate/click`
```
{ productId, brandId, userId, at }
```

## `config/...`
```
config/fitScoreWeights → { trendMatch, colorHarmony, styleConsistency, silhouetteBalance, accessories }
config/home            → { featuredBrandId }
```

> **Note:** This server uses the Firebase Admin SDK, which bypasses security rules.
> The same collections still need proper **Firestore Security Rules** for the
> Flutter app's direct access (e.g. a user can only write their own wardrobe).

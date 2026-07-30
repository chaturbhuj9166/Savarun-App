import { z } from 'zod';
import { db, admin } from '../config/firebase.js';
import { ApiError } from '../utils/ApiError.js';
import { asyncHandler } from '../utils/asyncHandler.js';

const LikeBody = z.object({ like: z.boolean() });

/**
 * POST /api/posts/:id/like   body: { like: boolean }
 * Toggle a like on an outfit post. Uses a per-user `postLikes/{postId}_{uid}`
 * marker for idempotency and keeps `posts.likes` as an atomic running count
 * (so the feed / inspiration grid can read popularity cheaply).
 */
export const toggleLike = asyncHandler(async (req, res) => {
  const parsed = LikeBody.safeParse(req.body);
  if (!parsed.success) throw ApiError.badRequest('like (boolean) is required');

  const postId = req.params.id;
  const uid = req.user.uid;
  const postRef = db.collection('posts').doc(postId);
  const likeRef = db.collection('postLikes').doc(`${postId}_${uid}`);

  const likes = await db.runTransaction(async (tx) => {
    const [post, existing] = await Promise.all([tx.get(postRef), tx.get(likeRef)]);
    if (!post.exists) throw ApiError.notFound('Post not found');

    const already = existing.exists;
    let count = post.data().likes || 0;

    if (parsed.data.like && !already) {
      tx.set(likeRef, { postId, uid, at: admin.firestore.FieldValue.serverTimestamp() });
      count += 1;
    } else if (!parsed.data.like && already) {
      tx.delete(likeRef);
      count = Math.max(0, count - 1);
    }
    tx.update(postRef, { likes: count });
    return count;
  });

  res.json({ ok: true, data: { postId, likes, liked: parsed.data.like } });
});

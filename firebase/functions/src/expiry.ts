import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Scheduled function: Expire posts older than 60 minutes.
 * Runs every 5 minutes.
 */
export const expirePosts = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const expiredPosts = await db
      .collection("posts")
      .where("status", "==", "active")
      .where("expires_at", "<=", now)
      .get();

    if (expiredPosts.empty) {
      console.log("No posts to expire.");
      return;
    }

    const batch = db.batch();
    let count = 0;

    for (const doc of expiredPosts.docs) {
      batch.update(doc.ref, { status: "expired" });
      count++;
    }

    await batch.commit();
    console.log(`Expired ${count} posts.`);
  });

/**
 * Scheduled function: Expire chats based on inactivity rules.
 * - If no messages from either user within 2 hours → expire
 * - If both have messaged, expire after 60 min inactivity
 * Runs every 5 minutes.
 */
export const expireChats = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const expiredChats = await db
      .collection("chats")
      .where("status", "==", "active")
      .where("expires_at", "<=", now)
      .get();

    if (expiredChats.empty) {
      console.log("No chats to expire.");
      return;
    }

    const batch = db.batch();
    let count = 0;

    for (const doc of expiredChats.docs) {
      batch.update(doc.ref, { status: "expired" });
      count++;

      // Also expire the associated match
      const chatData = doc.data();
      if (chatData.match_id) {
        const matchRef = db.collection("matches").doc(chatData.match_id);
        batch.update(matchRef, { status: "expired" });
      }
    }

    await batch.commit();
    console.log(`Expired ${count} chats (and their matches).`);
  });

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";

const db = admin.firestore();

/**
 * Triggered when a new interest is created.
 * Checks for mutual interest and creates a match + chat if found.
 */
export const onInterestCreate = functions.firestore
  .document("interests/{interestId}")
  .onCreate(async (snapshot, context) => {
    const interest = snapshot.data();
    const fromUser = interest.from_user;
    const toUser = interest.to_user;

    console.log(`Interest created: ${fromUser} → ${toUser}`);

    // Check for reverse interest (mutual)
    const reverseInterest = await db
      .collection("interests")
      .where("from_user", "==", toUser)
      .where("to_user", "==", fromUser)
      .limit(1)
      .get();

    if (reverseInterest.empty) {
      console.log("No mutual interest found. Silent.");
      return;
    }

    console.log(`Mutual interest found! Creating match: ${fromUser} ↔ ${toUser}`);

    // Check if match already exists
    const existingMatch = await db
      .collection("matches")
      .where("participants", "array-contains", fromUser)
      .where("status", "==", "active")
      .get();

    const alreadyMatched = existingMatch.docs.some((doc) => {
      const participants = doc.data().participants as string[];
      return participants.includes(toUser);
    });

    if (alreadyMatched) {
      console.log("Match already exists. Skipping.");
      return;
    }

    // Check if either user has blocked the other
    const blocks = await db
      .collection("blocks")
      .where("blocker_uid", "in", [fromUser, toUser])
      .get();

    const isBlocked = blocks.docs.some((doc) => {
      const data = doc.data();
      return (
        (data.blocker_uid === fromUser && data.blocked_uid === toUser) ||
        (data.blocker_uid === toUser && data.blocked_uid === fromUser)
      );
    });

    if (isBlocked) {
      console.log("One user has blocked the other. No match.");
      return;
    }

    const now = admin.firestore.Timestamp.now();
    const matchId = uuidv4();
    const chatId = uuidv4();
    const participants = [fromUser, toUser];

    // 2-hour initial response window
    const expiresAt = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + 2 * 60 * 60 * 1000
    );

    // Fetch user photos for chat document injection
    const userAPhotosDoc = await db.collection("user_photos").doc(fromUser).get();
    const userBPhotosDoc = await db.collection("user_photos").doc(toUser).get();
    const userAPhotos = userAPhotosDoc.exists ? userAPhotosDoc.data()?.photo_urls || [] : [];
    const userBPhotos = userBPhotosDoc.exists ? userBPhotosDoc.data()?.photo_urls || [] : [];

    const batch = db.batch();

    // Create match
    batch.set(db.collection("matches").doc(matchId), {
      match_id: matchId,
      user_a: fromUser,
      user_b: toUser,
      participants: participants,
      created_at: now,
      status: "active",
    });

    // Create chat
    batch.set(db.collection("chats").doc(chatId), {
      chat_id: chatId,
      participants: participants,
      participant_photos: {
        [fromUser]: userAPhotos,
        [toUser]: userBPhotos,
      },
      created_at: now,
      expires_at: expiresAt,
      status: "active",
      last_message: null,
      last_message_at: null,
      match_id: matchId,
    });

    await batch.commit();

    // Send push notifications to both users
    await sendMatchNotification(fromUser);
    await sendMatchNotification(toUser);

    console.log(`Match ${matchId} and chat ${chatId} created successfully.`);
  });

/**
 * Send "You have a match" notification
 */
async function sendMatchNotification(uid: string) {
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.data();

    if (!userData?.fcm_token) {
      console.log(`No FCM token for user ${uid}`);
      return;
    }

    await admin.messaging().send({
      token: userData.fcm_token,
      notification: {
        title: "Right Now",
        body: "You have a match! 🎉",
      },
      data: {
        type: "match",
      },
      android: {
        priority: "high",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    console.log(`Match notification sent to ${uid}`);
  } catch (error) {
    console.error(`Failed to send notification to ${uid}:`, error);
  }
}

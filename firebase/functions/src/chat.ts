import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";
import { filterMessage } from "./contentFilter";

const db = admin.firestore();

export const sendMessage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { chatId, text } = data;
  const senderId = context.auth.uid;

  if (!chatId || typeof chatId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Valid chatId is required"
    );
  }

  if (!text || typeof text !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Valid message text is required"
    );
  }

  // 1. Verify chat exists and user is participant
  const chatRef = db.collection("chats").doc(chatId);
  const chatDoc = await chatRef.get();

  if (!chatDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Chat not found");
  }

  const chatData = chatDoc.data();
  if (!chatData?.participants.includes(senderId)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "User is not a participant in this chat"
    );
  }

  if (chatData.status !== "active") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Chat is no longer active"
    );
  }

  // 2. Validate message content on the server side
  const filterResult = filterMessage(text);
  if (!filterResult.isAllowed) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      filterResult.reason || "Message blocked by content filter"
    );
  }

  const filteredText = filterResult.filteredText;
  const messageId = uuidv4();
  const now = admin.firestore.Timestamp.now();

  const batch = db.batch();

  // 3. Write message securely to subcollection using Admin SDK (bypasses rules)
  const messageRef = chatRef.collection("messages").doc(messageId);
  batch.set(messageRef, {
    message_id: messageId,
    sender_id: senderId,
    text: filteredText,
    created_at: now,
  });

  // 4. Update chat timestamp and extend expiry
  const newExpiryMs = now.toMillis() + 60 * 60 * 1000; // 60 mins chatInactivityExpiry
  batch.update(chatRef, {
    last_message: filteredText,
    last_message_at: now,
    expires_at: admin.firestore.Timestamp.fromMillis(newExpiryMs),
  });

  await batch.commit();

  return {
    success: true,
    messageId,
    filteredText,
  };
});

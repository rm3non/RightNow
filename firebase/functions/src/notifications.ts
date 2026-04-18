import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Triggered when a new message is created in a chat.
 * Sends a push notification to the recipient.
 */
export const onNewMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const { chatId } = context.params;
    const message = snapshot.data();
    const senderId = message.sender_id;
    const messageText = message.text;

    // Get chat to find the other participant
    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) return;

    const chatData = chatDoc.data()!;
    const participants = chatData.participants as string[];
    const recipientId = participants.find((uid: string) => uid !== senderId);

    if (!recipientId) return;

    // Get sender's name for notification
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.data()?.name_or_alias || "Someone";

    // Get recipient's FCM token
    const recipientDoc = await db.collection("users").doc(recipientId).get();
    const recipientData = recipientDoc.data();

    if (!recipientData?.fcm_token) {
      console.log(`No FCM token for recipient ${recipientId}`);
      return;
    }

    // Truncate message for preview
    const preview =
      messageText.length > 50
        ? messageText.substring(0, 50) + "..."
        : messageText;

    try {
      await admin.messaging().send({
        token: recipientData.fcm_token,
        notification: {
          title: senderName,
          body: preview,
        },
        data: {
          type: "message",
          chat_id: chatId,
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

      console.log(`Message notification sent to ${recipientId}`);
    } catch (error) {
      console.error(`Failed to send notification:`, error);
    }
  });

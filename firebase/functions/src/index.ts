import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// Re-export all function modules
export { onInterestCreate } from "./matching";
export { expirePosts, expireChats } from "./expiry";
export { onNewMessage } from "./notifications";
export { onReportCreate } from "./moderation";
export { sendMessage } from "./chat";

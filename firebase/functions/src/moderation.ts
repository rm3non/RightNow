import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

// Auto-flag threshold: number of reports before flagging
const REPORT_FLAG_THRESHOLD = 3;

/**
 * Triggered when a new report is created.
 * Auto-flags users with multiple reports.
 */
export const onReportCreate = functions.firestore
  .document("reports/{reportId}")
  .onCreate(async (snapshot) => {
    const report = snapshot.data();
    const targetUid = report.target_uid;

    console.log(`Report created against user ${targetUid}`);

    // Count total reports against this user
    const reportsSnapshot = await db
      .collection("reports")
      .where("target_uid", "==", targetUid)
      .get();

    const reportCount = reportsSnapshot.size;

    console.log(`User ${targetUid} has ${reportCount} report(s)`);

    if (reportCount >= REPORT_FLAG_THRESHOLD) {
      // Flag the user
      await db.collection("users").doc(targetUid).update({
        flagged: true,
        flagged_at: admin.firestore.FieldValue.serverTimestamp(),
        report_count: reportCount,
      });

      console.log(
        `User ${targetUid} has been flagged with ${reportCount} reports`
      );

      // Optional: deactivate user's active posts
      const activePosts = await db
        .collection("posts")
        .where("user_id", "==", targetUid)
        .where("status", "==", "active")
        .get();

      if (!activePosts.empty) {
        const batch = db.batch();
        for (const doc of activePosts.docs) {
          batch.update(doc.ref, { status: "expired" });
        }
        await batch.commit();
        console.log(`Expired active posts for flagged user ${targetUid}`);
      }
    }
  });

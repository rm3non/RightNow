import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../config/constants.dart';

/// Moderation service — reporting and blocking
class ModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _reportsRef =>
      _firestore.collection(AppConstants.reportsCollection);

  CollectionReference get _blocksRef =>
      _firestore.collection(AppConstants.blocksCollection);

  CollectionReference get _chatsRef =>
      _firestore.collection(AppConstants.chatsCollection);

  /// Report a user
  Future<void> reportUser({
    required String reporterUid,
    required String targetUid,
    required String reason,
    String? details,
  }) async {
    final reportId = _uuid.v4();
    final report = ReportModel(
      reportId: reportId,
      reporterUid: reporterUid,
      targetUid: targetUid,
      reason: reason,
      details: details,
      createdAt: DateTime.now(),
    );

    await _reportsRef.doc(reportId).set(report.toMap());
  }

  /// Block a user — ends all chats and prevents future matches
  Future<void> blockUser({
    required String blockerUid,
    required String blockedUid,
  }) async {
    final blockId = _uuid.v4();
    final block = BlockModel(
      blockId: blockId,
      blockerUid: blockerUid,
      blockedUid: blockedUid,
      createdAt: DateTime.now(),
    );

    // Create block record
    await _blocksRef.doc(blockId).set(block.toMap());

    // End all active chats between these users
    final chats = await _chatsRef
        .where('participants', arrayContains: blockerUid)
        .where('status', isEqualTo: 'active')
        .get();

    final batch = _firestore.batch();
    for (final chat in chats.docs) {
      final participants = List<String>.from(chat['participants'] ?? []);
      if (participants.contains(blockedUid)) {
        batch.update(chat.reference, {'status': 'blocked'});
      }
    }
    await batch.commit();
  }

  /// Get list of blocked user UIDs
  Future<List<String>> getBlockedUserIds(String uid) async {
    final blockedByMe = await _blocksRef
        .where('blocker_uid', isEqualTo: uid)
        .get();

    final blockedMe = await _blocksRef
        .where('blocked_uid', isEqualTo: uid)
        .get();

    final blockedIds = <String>{};
    for (final doc in blockedByMe.docs) {
      blockedIds.add(doc['blocked_uid'] as String);
    }
    for (final doc in blockedMe.docs) {
      blockedIds.add(doc['blocker_uid'] as String);
    }

    return blockedIds.toList();
  }

  /// Check if a user is blocked
  Future<bool> isBlocked(String uid, String otherUid) async {
    final blockedIds = await getBlockedUserIds(uid);
    return blockedIds.contains(otherUid);
  }
}

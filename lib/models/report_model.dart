import 'package:cloud_firestore/cloud_firestore.dart';

/// Report model matching Firestore reports/{reportId} document
class ReportModel {
  final String reportId;
  final String reporterUid;
  final String targetUid;
  final String reason;
  final String? details;
  final DateTime createdAt;

  const ReportModel({
    required this.reportId,
    required this.reporterUid,
    required this.targetUid,
    required this.reason,
    this.details,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'reporter_uid': reporterUid,
      'target_uid': targetUid,
      'reason': reason,
      'details': details,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      reportId: map['report_id'] ?? '',
      reporterUid: map['reporter_uid'] ?? '',
      targetUid: map['target_uid'] ?? '',
      reason: map['reason'] ?? '',
      details: map['details'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Block model matching Firestore blocks/{blockId} document
class BlockModel {
  final String blockId;
  final String blockerUid;
  final String blockedUid;
  final DateTime createdAt;

  const BlockModel({
    required this.blockId,
    required this.blockerUid,
    required this.blockedUid,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'block_id': blockId,
      'blocker_uid': blockerUid,
      'blocked_uid': blockedUid,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      blockId: map['block_id'] ?? '',
      blockerUid: map['blocker_uid'] ?? '',
      blockedUid: map['blocked_uid'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

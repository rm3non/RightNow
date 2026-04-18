import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// Match model matching Firestore matches/{matchId} document
class MatchModel {
  final String matchId;
  final String userA;
  final String userB;
  final List<String> participants;
  final DateTime createdAt;
  final MatchStatus status;

  const MatchModel({
    required this.matchId,
    required this.userA,
    required this.userB,
    required this.participants,
    required this.createdAt,
    this.status = MatchStatus.active,
  });

  /// Get the other user's UID given the current user
  String otherUser(String currentUid) {
    return currentUid == userA ? userB : userA;
  }

  Map<String, dynamic> toMap() {
    return {
      'match_id': matchId,
      'user_a': userA,
      'user_b': userB,
      'participants': participants,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status == MatchStatus.active ? 'active' : 'expired',
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      matchId: map['match_id'] ?? '',
      userA: map['user_a'] ?? '',
      userB: map['user_b'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] == 'active' ? MatchStatus.active : MatchStatus.expired,
    );
  }

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel.fromMap(data);
  }
}

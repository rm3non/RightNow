import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

/// Match service — reads matches created by Cloud Functions
class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _matchesRef =>
      _firestore.collection(AppConstants.matchesCollection);

  /// Stream of active matches for a user
  Stream<List<MatchModel>> getMatchesStream(String userId) {
    return _matchesRef
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MatchModel.fromFirestore(doc)).toList());
  }

  /// Get a single match
  Future<MatchModel?> getMatch(String matchId) async {
    final doc = await _matchesRef.doc(matchId).get();
    if (!doc.exists) return null;
    return MatchModel.fromFirestore(doc);
  }

  /// Get the partner's profile for a match (with photos for reveal)
  Future<UserModel?> getMatchPartner({
    required String matchId,
    required String currentUid,
  }) async {
    final match = await getMatch(matchId);
    if (match == null) return null;

    final partnerUid = match.otherUser(currentUid);
    final partnerDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(partnerUid)
        .get();

    if (!partnerDoc.exists) return null;
    return UserModel.fromFirestore(partnerDoc);
  }

  /// Check if two users already have an active match
  Future<bool> hasExistingMatch(String userA, String userB) async {
    final query = await _matchesRef
        .where('participants', arrayContains: userA)
        .where('status', isEqualTo: 'active')
        .get();

    return query.docs.any((doc) {
      final participants = List<String>.from(doc['participants'] ?? []);
      return participants.contains(userB);
    });
  }
}

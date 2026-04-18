import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/interest_model.dart';
import '../config/constants.dart';

/// Interest service — handles "I'm in" taps (silent, no notifications)
class InterestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _interestsRef =>
      _firestore.collection(AppConstants.interestsCollection);

  /// Express interest in a post (silent action)
  /// The Cloud Function onInterestCreate will handle mutual matching
  Future<void> expressInterest({
    required String fromUser,
    required String toUser,
    required String toPost,
  }) async {
    // Check if already expressed interest in this post
    final existing = await _interestsRef
        .where('from_user', isEqualTo: fromUser)
        .where('to_post', isEqualTo: toPost)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // Already expressed interest

    final id = _uuid.v4();
    final interest = InterestModel(
      id: id,
      fromUser: fromUser,
      toUser: toUser,
      toPost: toPost,
      createdAt: DateTime.now(),
    );

    await _interestsRef.doc(id).set(interest.toMap());
  }

  /// Check if user has already expressed interest in a post
  Future<bool> hasExpressedInterest({
    required String fromUser,
    required String toPost,
  }) async {
    final query = await _interestsRef
        .where('from_user', isEqualTo: fromUser)
        .where('to_post', isEqualTo: toPost)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Get all interests sent by a user (for UI state)
  Stream<List<String>> getSentInterestPostIds(String userId) {
    return _interestsRef
        .where('from_user', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['to_post'] as String).toList());
  }
}

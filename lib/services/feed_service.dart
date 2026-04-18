import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

/// Feed service — handles filtered, mode-isolated feed queries
class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _postsRef =>
      _firestore.collection(AppConstants.postsCollection);

  /// Get filtered feed stream for a user.
  /// Enforces Safe/Open mode separation at query level.
  Stream<List<PostModel>> getFeedStream({
    required UserModel currentUser,
    IntentType? intentTypeFilter,
  }) {
    Query query = _postsRef
        .where('status', isEqualTo: 'active')
        .orderBy('created_at', descending: true);

    // CRITICAL: Mode isolation
    // Safe users see ONLY safe posts
    // Open users see safe + open (all)
    if (currentUser.contentMode == ContentMode.safe) {
      query = query.where('user_content_mode', isEqualTo: 'safe');
    }

    // Filter by intent type if specified
    if (intentTypeFilter != null) {
      query = query.where('intent_type', isEqualTo: intentTypeFilter.value);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((post) => _shouldShowPost(post, currentUser))
          .toList();
    });
  }

  /// Apply client-side filters that can't be done in a single Firestore query
  bool _shouldShowPost(PostModel post, UserModel currentUser) {
    // Don't show own posts
    if (post.userId == currentUser.uid) return false;

    // Don't show expired posts (client-side check for race conditions)
    if (post.isExpired) return false;

    // Gender preference filter
    if (!_matchesGenderPreference(post, currentUser)) return false;

    // Couples visibility: hide couples unless user is in open mode
    if (post.userRelationshipType == 'couple' &&
        currentUser.contentMode == ContentMode.safe) {
      return false;
    }

    return true;
  }

  /// Check if the post author matches the current user's gender preference
  /// and vice versa
  bool _matchesGenderPreference(PostModel post, UserModel currentUser) {
    final postGender = post.userGender;
    final userPreference = currentUser.preference;

    // If user wants everyone, no filter needed on user side
    if (userPreference != Preference.everyone) {
      // Check if post author's gender matches user's preference
      if (userPreference == Preference.men && postGender != 'man') return false;
      if (userPreference == Preference.women && postGender != 'woman') return false;
    }

    // Check if post author's preference includes current user's gender
    final postPreference = post.userPreference;
    if (postPreference != null && postPreference != 'everyone') {
      if (postPreference == 'men' && currentUser.gender != Gender.man) return false;
      if (postPreference == 'women' && currentUser.gender != Gender.woman) return false;
    }

    return true;
  }

  /// Get feed as a one-time fetch (for initial load)
  Future<List<PostModel>> getFeed({
    required UserModel currentUser,
    int limit = 50,
  }) async {
    Query query = _postsRef
        .where('status', isEqualTo: 'active')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (currentUser.contentMode == ContentMode.safe) {
      query = query.where('user_content_mode', isEqualTo: 'safe');
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .where((post) => _shouldShowPost(post, currentUser))
        .toList();
  }
}

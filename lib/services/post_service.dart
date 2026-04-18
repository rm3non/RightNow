import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

/// Intent post creation and management
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _postsRef =>
      _firestore.collection(AppConstants.postsCollection);

  /// Create a new intent post. Replaces any existing active post.
  Future<PostModel> createPost({
    required UserModel user,
    required String text,
    required IntentType intentType,
  }) async {
    // Validate: safe users cannot create open intent
    if (user.contentMode == ContentMode.safe && intentType == IntentType.open) {
      throw Exception('Safe mode users cannot create Open intents');
    }

    // Validate text length
    if (text.length > AppConstants.maxIntentLength) {
      throw Exception('Intent text must be ${AppConstants.maxIntentLength} characters or less');
    }

    // Expire any existing active post by this user
    await _expireUserActivePosts(user.uid);

    final now = DateTime.now();
    final postId = _uuid.v4();
    final post = PostModel(
      postId: postId,
      userId: user.uid,
      text: text,
      intentType: intentType,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: AppConstants.postExpiryMinutes)),
      status: PostStatus.active,
      // Denormalized user fields for feed efficiency
      userNameOrAlias: user.nameOrAlias,
      userAge: user.age,
      userGender: user.gender.value,
      userPreference: user.preference.value,
      userRelationshipType: user.relationshipType.value,
      userContentMode: user.contentMode.value,
    );

    await _postsRef.doc(postId).set(post.toMap());
    return post;
  }

  /// Expire all active posts by a user (before creating new one)
  Future<void> _expireUserActivePosts(String userId) async {
    final activeQuery = await _postsRef
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    final batch = _firestore.batch();
    for (final doc in activeQuery.docs) {
      batch.update(doc.reference, {'status': 'expired'});
    }
    await batch.commit();
  }

  /// Get current user's active post
  Future<PostModel?> getUserActivePost(String userId) async {
    final query = await _postsRef
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return PostModel.fromFirestore(query.docs.first);
  }

  /// Stream of current user's active post
  Stream<PostModel?> getUserActivePostStream(String userId) {
    return _postsRef
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return PostModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Delete/expire a post
  Future<void> expirePost(String postId) async {
    await _postsRef.doc(postId).update({'status': 'expired'});
  }
}

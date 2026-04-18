import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

/// User profile CRUD operations
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Create a new user profile
  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toMap());
  }

  /// Get user by UID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Update user profile fields
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    updates['last_active'] = Timestamp.fromDate(DateTime.now());
    await _usersRef.doc(uid).update(updates);
  }

  /// Update content mode (safe/open) with validation
  Future<void> updateContentMode(String uid, ContentMode mode) async {
    await _usersRef.doc(uid).update({
      'content_mode': mode.value,
      'last_active': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Mark user as verified after selfie verification
  Future<void> verifyUser(String uid) async {
    await _usersRef.doc(uid).update({
      'verified': true,
      'last_active': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Add photo URL to user_photos
  Future<void> addPhotoUrl(String uid, String photoUrl) async {
    // Merge true ensures document is created if it does not exist
    await _firestore.collection('user_photos').doc(uid).set({
      'photo_urls': FieldValue.arrayUnion([photoUrl]),
      'last_updated': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
    
    // Also update last_active on the main user profile
    await updateLastActive(uid);
  }

  /// Remove photo URL from user_photos
  Future<void> removePhotoUrl(String uid, String photoUrl) async {
    await _firestore.collection('user_photos').doc(uid).set({
      'photo_urls': FieldValue.arrayRemove([photoUrl]),
      'last_updated': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
    
    await updateLastActive(uid);
  }

  /// Stream user's private photos
  Stream<List<String>> getUserPhotosStream(String uid) {
    return _firestore.collection('user_photos').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data();
      return List<String>.from(data?['photo_urls'] ?? []);
    });
  }

  /// Update last active timestamp
  Future<void> updateLastActive(String uid) async {
    await _usersRef.doc(uid).update({
      'last_active': Timestamp.fromDate(DateTime.now()),
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// Intent post model matching Firestore posts/{postId} document
class PostModel {
  final String postId;
  final String userId;
  final String text;
  final IntentType intentType;
  final DateTime createdAt;
  final DateTime expiresAt;
  final PostStatus status;

  // Denormalized fields for feed display (avoid extra reads)
  final String? userNameOrAlias;
  final int? userAge;
  final String? userGender;
  final String? userPreference;
  final String? userRelationshipType;
  final String? userContentMode;

  const PostModel({
    required this.postId,
    required this.userId,
    required this.text,
    required this.intentType,
    required this.createdAt,
    required this.expiresAt,
    this.status = PostStatus.active,
    this.userNameOrAlias,
    this.userAge,
    this.userGender,
    this.userPreference,
    this.userRelationshipType,
    this.userContentMode,
  });

  bool get isExpired =>
      status == PostStatus.expired || DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'user_id': userId,
      'text': text,
      'intent_type': intentType.value,
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'status': status == PostStatus.active ? 'active' : 'expired',
      'user_name_or_alias': userNameOrAlias,
      'user_age': userAge,
      'user_gender': userGender,
      'user_preference': userPreference,
      'user_relationship_type': userRelationshipType,
      'user_content_mode': userContentMode,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      postId: map['post_id'] ?? '',
      userId: map['user_id'] ?? '',
      text: map['text'] ?? '',
      intentType: IntentTypeExtension.fromString(map['intent_type'] ?? 'talk'),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expires_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] == 'active' ? PostStatus.active : PostStatus.expired,
      userNameOrAlias: map['user_name_or_alias'],
      userAge: map['user_age'],
      userGender: map['user_gender'],
      userPreference: map['user_preference'],
      userRelationshipType: map['user_relationship_type'],
      userContentMode: map['user_content_mode'],
    );
  }

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel.fromMap(data);
  }
}

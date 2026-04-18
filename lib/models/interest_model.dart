import 'package:cloud_firestore/cloud_firestore.dart';

/// Interest model matching Firestore interests/{id} document
class InterestModel {
  final String id;
  final String fromUser;
  final String toUser;
  final String toPost;
  final DateTime createdAt;

  const InterestModel({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.toPost,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'from_user': fromUser,
      'to_user': toUser,
      'to_post': toPost,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory InterestModel.fromMap(Map<String, dynamic> map) {
    return InterestModel(
      id: map['id'] ?? '',
      fromUser: map['from_user'] ?? '',
      toUser: map['to_user'] ?? '',
      toPost: map['to_post'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory InterestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InterestModel.fromMap(data);
  }
}

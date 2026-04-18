import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// User profile model matching Firestore users/{uid} document
class UserModel {
  final String uid;
  final String nameOrAlias;
  final int age;
  final Gender gender;
  final Preference preference;
  final RelationshipType relationshipType;
  final ContentMode contentMode;
  final List<String> photoUrls;
  final bool verified;
  final DateTime createdAt;
  final DateTime lastActive;

  const UserModel({
    required this.uid,
    required this.nameOrAlias,
    required this.age,
    required this.gender,
    required this.preference,
    required this.relationshipType,
    this.contentMode = ContentMode.safe,
    this.photoUrls = const [],
    this.verified = false,
    required this.createdAt,
    required this.lastActive,
  });

  /// Whether this user can see Open-mode content
  bool get isOpenEnabled => contentMode == ContentMode.openEnabled;

  /// Whether profile is complete enough to activate
  bool get isProfileComplete =>
      nameOrAlias.isNotEmpty && age > 0 && photoUrls.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name_or_alias': nameOrAlias,
      'age': age,
      'gender': gender.value,
      'preference': preference.value,
      'relationship_type': relationshipType.value,
      'content_mode': contentMode.value,
      'photo_urls': photoUrls,
      'verified': verified,
      'created_at': Timestamp.fromDate(createdAt),
      'last_active': Timestamp.fromDate(lastActive),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      nameOrAlias: map['name_or_alias'] ?? '',
      age: map['age'] ?? 0,
      gender: GenderExtension.fromString(map['gender'] ?? 'man'),
      preference: PreferenceExtension.fromString(map['preference'] ?? 'everyone'),
      relationshipType: RelationshipTypeExtension.fromString(
        map['relationship_type'] ?? 'solo',
      ),
      contentMode: ContentModeExtension.fromString(
        map['content_mode'] ?? 'safe',
      ),
      photoUrls: List<String>.from(map['photo_urls'] ?? []),
      verified: map['verified'] ?? false,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['last_active'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  UserModel copyWith({
    String? uid,
    String? nameOrAlias,
    int? age,
    Gender? gender,
    Preference? preference,
    RelationshipType? relationshipType,
    ContentMode? contentMode,
    List<String>? photoUrls,
    bool? verified,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nameOrAlias: nameOrAlias ?? this.nameOrAlias,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      preference: preference ?? this.preference,
      relationshipType: relationshipType ?? this.relationshipType,
      contentMode: contentMode ?? this.contentMode,
      photoUrls: photoUrls ?? this.photoUrls,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

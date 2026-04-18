import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// Chat model matching Firestore chats/{chatId} document
class ChatModel {
  final String chatId;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime expiresAt;
  final ChatStatus status;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? matchId;
  final Map<String, List<String>> participantPhotos;

  const ChatModel({
    required this.chatId,
    required this.participants,
    required this.createdAt,
    required this.expiresAt,
    this.status = ChatStatus.active,
    this.lastMessage,
    this.lastMessageAt,
    this.matchId,
    this.participantPhotos = const {},
  });

  bool get isExpired =>
      status == ChatStatus.expired || DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  /// Get the other user's UID given the current user
  String otherUser(String currentUid) {
    return participants.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'participants': participants,
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'status': status.name,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'match_id': matchId,
      'participant_photos': participantPhotos,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chat_id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expires_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ChatStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'active'),
        orElse: () => ChatStatus.active,
      ),
      lastMessage: map['last_message'],
      lastMessageAt: (map['last_message_at'] as Timestamp?)?.toDate(),
      matchId: map['match_id'],
      participantPhotos: (map['participant_photos'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v ?? [])),
          ) ?? {},
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel.fromMap(data);
  }
}

/// Message model matching Firestore chats/{chatId}/messages/{messageId}
class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'text': text,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['message_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromMap(data);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../config/constants.dart';
import '../utils/content_filter.dart';

/// Chat service — manages chats and messages with content filtering
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _chatsRef =>
      _firestore.collection(AppConstants.chatsCollection);

  /// Stream of active chats for a user
  Stream<List<ChatModel>> getChatsStream(String userId) {
    return _chatsRef
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('last_message_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList());
  }

  /// Get a single chat
  Future<ChatModel?> getChat(String chatId) async {
    final doc = await _chatsRef.doc(chatId).get();
    if (!doc.exists) return null;
    return ChatModel.fromFirestore(doc);
  }

  /// Stream a single chat for real-time updates
  Stream<ChatModel?> getChatStream(String chatId) {
    return _chatsRef.doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatModel.fromFirestore(doc);
    });
  }

  /// Stream messages for a chat
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection(AppConstants.messagesSubcollection)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  /// Send a message with content filtering (via Cloud Function)
  Future<MessageModel?> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    // 1. Initial quick client-side filtering for fast UX
    final localFilterResult = ContentFilter.filterMessage(text);
    if (!localFilterResult.isAllowed) {
      throw ContentFilterException(localFilterResult.reason ?? 'Message blocked');
    }

    try {
      // 2. Call secure Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('sendMessage');
      final result = await callable.call({
        'chatId': chatId,
        'text': text,
      });

      final data = result.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return MessageModel(
          messageId: data['messageId'] ?? _uuid.v4(),
          senderId: senderId,
          text: data['filteredText'] ?? text,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } on FirebaseFunctionsException catch (e) {
      throw ContentFilterException(e.message ?? 'Message blocked by server');
    } catch (e) {
      throw ContentFilterException('Failed to send message: $e');
    }
  }

  /// End a chat (used when blocking)
  Future<void> endChat(String chatId) async {
    await _chatsRef.doc(chatId).update({
      'status': 'blocked',
    });
  }
}

/// Exception thrown when content filter blocks a message
class ContentFilterException implements Exception {
  final String message;
  const ContentFilterException(this.message);

  @override
  String toString() => message;
}

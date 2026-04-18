import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

/// Chat state management
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  List<ChatModel> _chats = [];
  final Map<String, UserModel> _chatPartners = {};
  List<MessageModel> _currentMessages = [];
  ChatModel? _currentChat;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _chatsSub;
  StreamSubscription? _messagesSub;
  StreamSubscription? _chatSub;

  List<ChatModel> get chats => _chats;
  Map<String, UserModel> get chatPartners => _chatPartners;
  List<MessageModel> get currentMessages => _currentMessages;
  ChatModel? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize chat list listener
  void initChats(String userId) {
    _chatsSub?.cancel();
    _chatsSub = _chatService.getChatsStream(userId).listen((chats) {
      _chats = chats;
      _loadChatPartners(userId);
      notifyListeners();
    });
  }

  /// Load partner profiles for chat list
  Future<void> _loadChatPartners(String currentUid) async {
    for (final chat in _chats) {
      final partnerUid = chat.otherUser(currentUid);
      if (partnerUid.isNotEmpty && !_chatPartners.containsKey(partnerUid)) {
        final partner = await _userService.getUser(partnerUid);
        if (partner != null) {
          _chatPartners[partnerUid] = partner;
        }
      }
    }
    notifyListeners();
  }

  /// Open a specific chat and listen to messages
  void openChat(String chatId) {
    _messagesSub?.cancel();
    _chatSub?.cancel();

    // Listen to chat document for timer/status updates
    _chatSub = _chatService.getChatStream(chatId).listen((chat) {
      _currentChat = chat;
      notifyListeners();
    });

    // Listen to messages
    _messagesSub = _chatService.getMessagesStream(chatId).listen((messages) {
      _currentMessages = messages;
      notifyListeners();
    });
  }

  /// Send a message
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    _errorMessage = null;

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        text: text,
      );
      return true;
    } on ContentFilterException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send message';
      notifyListeners();
      return false;
    }
  }

  /// Close current chat (stop listening)
  void closeChat() {
    _messagesSub?.cancel();
    _chatSub?.cancel();
    _currentMessages = [];
    _currentChat = null;
    notifyListeners();
  }

  /// Get partner for a chat
  UserModel? getPartner(String partnerUid) => _chatPartners[partnerUid];

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    _messagesSub?.cancel();
    _chatSub?.cancel();
    super.dispose();
  }
}

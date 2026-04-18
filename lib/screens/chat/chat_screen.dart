import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/moderation_service.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart';
import '../../config/theme.dart';
import '../../utils/time_utils.dart';
import '../../widgets/photo_reveal_card.dart';
import '../../widgets/timer_badge.dart';
import '../../widgets/report_dialog.dart';

/// Chat screen — messages, photo reveal, timer, report/block
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String partnerUid;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.partnerUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final ModerationService _moderationService = ModerationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openChat(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatProvider>().closeChat();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final uid = context.read<AuthProvider>().uid;
    if (uid == null) return;

    _messageController.clear();

    final success = await context.read<ChatProvider>().sendMessage(
          chatId: widget.chatId,
          senderId: uid,
          text: text,
        );

    if (!success && mounted) {
      final error = context.read<ChatProvider>().errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.error,
          ),
        );
        context.read<ChatProvider>().clearError();
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showReportDialog() {
    final uid = context.read<AuthProvider>().uid;
    if (uid == null) return;

    showDialog(
      context: context,
      builder: (_) => ReportDialog(
        targetUid: widget.partnerUid,
        onReport: (reason, details) {
          _moderationService.reportUser(
            reporterUid: uid,
            targetUid: widget.partnerUid,
            reason: reason,
            details: details,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    );
  }

  void _blockUser() {
    final uid = context.read<AuthProvider>().uid;
    if (uid == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Block User'),
        content: const Text(
          'This will end the chat and prevent future matches. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _moderationService.blockUser(
                blockerUid: uid,
                blockedUid: widget.partnerUid,
              );
              if (mounted) Navigator.pop(context); // Leave chat
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final uid = context.watch<AuthProvider>().uid ?? '';
    final partner = chatProvider.getPartner(widget.partnerUid);
    final chat = chatProvider.currentChat;
    final messages = chatProvider.currentMessages;

    // Use photos injected securely by the backend into the Chat payload
    final partnerPhotos = chat?.participantPhotos[widget.partnerUid] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            // Partner name
            Expanded(
              child: Text(
                partner?.nameOrAlias ?? 'Chat',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            // Timer
            if (chat != null)
              TimerBadge(expiresAt: chat.expiresAt, isCompact: true),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            color: AppTheme.surface,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'report', child: Text('Report')),
              const PopupMenuItem(
                value: 'block',
                child: Text('Block', style: TextStyle(color: AppTheme.error)),
              ),
            ],
            onSelected: (value) {
              if (value == 'report') _showReportDialog();
              if (value == 'block') _blockUser();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo reveal
          if (partner != null && partnerPhotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: PhotoRevealCard(
                photoUrls: partnerPhotos,
                name: partner.nameOrAlias,
              ),
            ),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyChat(partner)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == uid;
                      return _MessageBubble(
                        text: msg.text,
                        time: msg.createdAt,
                        isMe: isMe,
                      );
                    },
                  ),
          ),

          // Input bar
          _buildInputBar(chat),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(UserModel? partner) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration_outlined,
              color: AppTheme.accent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'You matched with ${partner?.nameOrAlias ?? "someone"}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Say something to start the conversation.\nRemember, this chat is time-bound!',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(dynamic chat) {
    final isExpired = chat != null && chat.isExpired;

    if (isExpired) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppTheme.surface,
        child: const Center(
          child: Text(
            'This chat has expired',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      color: AppTheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppTheme.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final String text;
  final DateTime time;
  final bool isMe;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : AppTheme.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : AppTheme.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TimeUtils.formatTime(time),
              style: TextStyle(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

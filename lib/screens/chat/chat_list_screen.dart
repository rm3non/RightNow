import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../utils/time_utils.dart';
import 'chat_screen.dart';

/// Chat list screen — shows all active chats
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final uid = context.watch<AuthProvider>().uid;

    if (uid == null) return const SizedBox.shrink();

    if (chatProvider.chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.textMuted,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No chats yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Match with someone to start chatting',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatProvider.chats.length,
      itemBuilder: (context, index) {
        final chat = chatProvider.chats[index];
        final partnerUid = chat.otherUser(uid);
        final partner = chatProvider.getPartner(partnerUid);

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: SizedBox(
              width: 52,
              height: 52,
              child: partner != null && partner.photoUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: partner.photoUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppTheme.surfaceLight),
                    )
                  : Container(
                      color: AppTheme.surfaceLight,
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.textMuted,
                      ),
                    ),
            ),
          ),
          title: Text(
            partner?.nameOrAlias ?? 'Loading...',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            chat.lastMessage ?? 'Start a conversation',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: chat.lastMessage != null
                  ? AppTheme.textSecondary
                  : AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (chat.lastMessageAt != null)
                Text(
                  TimeUtils.formatRelative(chat.lastMessageAt!),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              const SizedBox(height: 4),
              // Timer indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: chat.timeRemaining.inMinutes > 30
                      ? AppTheme.success
                      : chat.timeRemaining.inMinutes > 10
                          ? AppTheme.warning
                          : AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: chat.chatId,
                  partnerUid: partnerUid,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

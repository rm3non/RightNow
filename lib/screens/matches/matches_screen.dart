import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/match_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../utils/time_utils.dart';
import '../chat/chat_screen.dart';

/// Matches screen — shows list of mutual matches with revealed photos
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchProvider = context.watch<MatchProvider>();
    final uid = context.watch<AuthProvider>().uid;

    if (uid == null) return const SizedBox.shrink();

    // Clear unread count when viewing matches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (matchProvider.hasNewMatches) {
        matchProvider.clearUnreadCount();
      }
    });

    if (matchProvider.matches.isEmpty) {
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
                  Icons.favorite_outline,
                  color: AppTheme.textMuted,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No matches yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'When you and someone both tap "I\'m in",\nyou\'ll match here',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matchProvider.matches.length,
      itemBuilder: (context, index) {
        final match = matchProvider.matches[index];
        final partnerUid = match.otherUser(uid);
        final partner = matchProvider.getPartner(partnerUid);

        return GestureDetector(
          onTap: () {
            // Navigate to chat screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: match.matchId,
                  partnerUid: partnerUid,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Photo reveal!
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: partner != null && partner.photoUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: partner.photoUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppTheme.surfaceLight,
                            ),
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner?.nameOrAlias ?? 'Loading...',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matched ${TimeUtils.formatRelative(match.createdAt)}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: const Text(
                    'Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

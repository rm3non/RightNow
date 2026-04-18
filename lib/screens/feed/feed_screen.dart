import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/post_model.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/intent_chip.dart';
import '../../widgets/timer_badge.dart';
import '../../utils/time_utils.dart';

/// Feed screen — displays intent cards, no photos
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return Column(
      children: [
        // Filter chips
        _buildFilterBar(context, feedProvider, user),

        // Feed list
        Expanded(
          child: feedProvider.feedPosts.isEmpty
              ? _buildEmptyFeed(context, feedProvider)
              : RefreshIndicator(
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  onRefresh: () async {
                    feedProvider.initFeed(user);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: feedProvider.feedPosts.length,
                    itemBuilder: (context, index) {
                      final post = feedProvider.feedPosts[index];
                      return _FeedCard(
                        post: post,
                        hasExpressedInterest:
                            feedProvider.hasExpressedInterest(post.postId),
                        onImIn: () {
                          final uid = context.read<AuthProvider>().uid;
                          if (uid != null) {
                            feedProvider.expressInterest(
                              fromUser: uid,
                              post: post,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
      BuildContext context, FeedProvider feedProvider, dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: feedProvider.intentFilter == null,
              onTap: () => feedProvider.setIntentFilter(null, user),
            ),
            const SizedBox(width: 8),
            ...IntentType.values
                .where((type) =>
                    type != IntentType.open ||
                    user.contentMode == ContentMode.openEnabled)
                .map((type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: '${type.emoji} ${type.displayName}',
                        isSelected: feedProvider.intentFilter == type,
                        onTap: () => feedProvider.setIntentFilter(type, user),
                        color: AppTheme.intentColor(type.value),
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeed(BuildContext context, FeedProvider feedProvider) {
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
                Icons.explore_outlined,
                color: AppTheme.textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No intents right now',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to post what you\'re looking for',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Feed card widget — shows name, age, intent text, intent tag, "I'm in" button
class _FeedCard extends StatelessWidget {
  final PostModel post;
  final bool hasExpressedInterest;
  final VoidCallback onImIn;

  const _FeedCard({
    required this.post,
    required this.hasExpressedInterest,
    required this.onImIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.surfaceLighter.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: name, age, timer
          Row(
            children: [
              // Avatar placeholder (no photo!)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (post.userNameOrAlias ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${post.userNameOrAlias ?? 'Anonymous'}, ${post.userAge ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      TimeUtils.formatRelative(post.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TimerBadge(expiresAt: post.expiresAt, isCompact: true),
            ],
          ),

          const SizedBox(height: 16),

          // Intent text
          Text(
            post.text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Footer: intent chip + I'm in button
          Row(
            children: [
              IntentChip(intentType: post.intentType),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: hasExpressedInterest
                    ? Container(
                        key: const ValueKey('expressed'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.success,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Sent',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Material(
                        key: const ValueKey('im_in'),
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onImIn,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusFull),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              "I'm in",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Filter chip for intent types
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.2)
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? chipColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

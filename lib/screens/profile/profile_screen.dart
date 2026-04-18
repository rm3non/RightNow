import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/intent_chip.dart';
import '../../widgets/timer_badge.dart';
import '../settings/settings_screen.dart';

/// Profile screen — shows user's profile, active intent, and settings access
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final feedProvider = context.watch<FeedProvider>();
    final user = userProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(context, user),

          const SizedBox(height: 24),

          // Active intent
          _buildActiveIntent(context, feedProvider),

          const SizedBox(height: 24),

          // Profile info cards
          _buildInfoCard(
            context,
            icon: Icons.person_outline,
            label: 'Gender',
            value: user.gender.displayName,
          ),
          _buildInfoCard(
            context,
            icon: Icons.favorite_outline,
            label: 'Interested in',
            value: user.preference.displayName,
          ),
          _buildInfoCard(
            context,
            icon: Icons.people_outline,
            label: 'Relationship',
            value: user.relationshipType.displayName,
          ),
          _buildInfoCard(
            context,
            icon: user.contentMode == ContentMode.safe
                ? Icons.shield_outlined
                : Icons.lock_open_outlined,
            label: 'Mode',
            value: user.contentMode.displayName,
            valueColor: user.contentMode == ContentMode.safe
                ? AppTheme.success
                : AppTheme.warning,
          ),

          const SizedBox(height: 24),

          // Settings button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Settings'),
            ),
          ),

          const SizedBox(height: 12),

          // Sign out
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.read<AuthProvider>().signOut(),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return Column(
      children: [
        // Photos carousel
        if (user.photoUrls.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: user.photoUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: SizedBox(
                    width: 90,
                    height: 120,
                    child: CachedNetworkImage(
                      imageUrl: user.photoUrls[index],
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppTheme.surfaceLight),
                    ),
                  ),
                );
              },
            ),
          )
        else
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.nameOrAlias[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        Text(
          '${user.nameOrAlias}, ${user.age}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),

        // Verified badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.verified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: AppTheme.success, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveIntent(BuildContext context, FeedProvider feedProvider) {
    final post = feedProvider.activePost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: post != null && !post.isExpired
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.surfaceLighter,
        ),
      ),
      child: post != null && !post.isExpired
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Your active intent',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TimerBadge(expiresAt: post.expiresAt, isCompact: true),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IntentChip(intentType: post.intentType, isCompact: true),
                    const Spacer(),
                    TextButton(
                      onPressed: () => feedProvider.expireActivePost(),
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : const Column(
              children: [
                Icon(
                  Icons.edit_note_outlined,
                  color: AppTheme.textMuted,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'No active intent',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Post one from the feed tab',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

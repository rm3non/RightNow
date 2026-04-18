import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

/// Settings screen — content mode toggle, profile editing, account actions
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Content Mode Toggle
          _buildSectionHeader(context, 'Content Mode'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Open Mode',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Allow adult intents and see Open posts',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: user.contentMode == ContentMode.openEnabled,
                      activeColor: AppTheme.warning,
                      onChanged: (enabled) {
                        if (enabled) {
                          _showOpenModeWarning(context, userProvider);
                        } else {
                          userProvider.toggleContentMode();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: user.contentMode == ContentMode.safe
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        user.contentMode == ContentMode.safe
                            ? Icons.shield_outlined
                            : Icons.warning_amber_outlined,
                        size: 18,
                        color: user.contentMode == ContentMode.safe
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.contentMode == ContentMode.safe
                              ? 'Safe mode active — only Talk, Meet, Date intents visible'
                              : 'Open mode — adult intents visible. Text only, no explicit content.',
                          style: TextStyle(
                            fontSize: 12,
                            color: user.contentMode == ContentMode.safe
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Profile section
          _buildSectionHeader(context, 'Profile'),
          _buildSettingsTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            subtitle: 'Name, age, preferences',
            onTap: () {
              // TODO: Navigate to edit profile
            },
          ),
          _buildSettingsTile(
            icon: Icons.photo_library_outlined,
            title: 'Manage Photos',
            subtitle: '${user.photoUrls.length}/${AppConstants.maxPhotos} photos',
            onTap: () {
              // TODO: Navigate to photo management
            },
          ),

          const SizedBox(height: 24),

          // Safety
          _buildSectionHeader(context, 'Safety & Privacy'),
          _buildSettingsTile(
            icon: Icons.block_outlined,
            title: 'Blocked Users',
            subtitle: 'Manage blocked accounts',
            onTap: () {
              // TODO: Navigate to blocked users
            },
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // App info
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: AppConstants.appVersion,
            showArrow: false,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        tileColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              )
            : null,
        trailing: showArrow
            ? const Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
                size: 20,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showOpenModeWarning(BuildContext context, UserProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Enable Open Mode'),
          ],
        ),
        content: const Text(
          'Open mode allows adult intent posts (text only). '
          'You will see posts from Open mode users in addition to Safe mode users.\n\n'
          'Rules:\n'
          '• No nudity or explicit images\n'
          '• No media sharing\n'
          '• No contact sharing\n'
          '• Text-based interactions only',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.toggleContentMode();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.black,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}

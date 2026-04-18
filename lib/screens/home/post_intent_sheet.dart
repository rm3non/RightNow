import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/user_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../utils/content_filter.dart';

/// Bottom sheet for creating a new intent post
class PostIntentSheet extends StatefulWidget {
  const PostIntentSheet({super.key});

  @override
  State<PostIntentSheet> createState() => _PostIntentSheetState();
}

class _PostIntentSheetState extends State<PostIntentSheet> {
  final _textController = TextEditingController();
  IntentType _selectedIntent = IntentType.talk;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() async {
    final feedProvider = context.read<FeedProvider>();
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return;

    final success = await feedProvider.createPost(
      user: user,
      text: _textController.text.trim(),
      intentType: _selectedIntent,
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final user = context.watch<UserProvider>().currentUser;
    final isOpenEnabled = user?.contentMode == ContentMode.openEnabled;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLighter,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'What are you looking for?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Post your intent. Others will see this — not your photos.',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 24),

          // Intent type selector
          Row(
            children: IntentType.values
                .where((type) => type != IntentType.open || isOpenEnabled)
                .map((type) {
              final isSelected = _selectedIntent == type;
              final color = AppTheme.intentColor(type.value);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIntent = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : AppTheme.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            type.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              color: isSelected ? color : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Text input
          TextField(
            controller: _textController,
            maxLength: AppConstants.maxIntentLength,
            maxLines: 2,
            autofocus: true,
            style: const TextStyle(fontSize: 16, height: 1.4),
            decoration: InputDecoration(
              hintText: _getHintText(),
              counterStyle: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          // Error
          if (feedProvider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              feedProvider.errorMessage!,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ],

          const SizedBox(height: 16),

          // Post button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canSubmit() && !feedProvider.isPostingIntent
                  ? _submit
                  : null,
              child: feedProvider.isPostingIntent
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post Intent'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return false;
    final filterResult = ContentFilter.filterIntentText(text);
    return filterResult.isAllowed;
  }

  String _getHintText() {
    switch (_selectedIntent) {
      case IntentType.talk:
        return 'e.g. "need someone to vent to"';
      case IntentType.meet:
        return 'e.g. "coffee in Koramangala?"';
      case IntentType.date:
        return 'e.g. "walk. no small talk"';
      case IntentType.open:
        return 'e.g. "open to anything tonight"';
    }
  }
}

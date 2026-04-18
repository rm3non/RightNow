import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

/// Color-coded intent type chip widget
class IntentChip extends StatelessWidget {
  final IntentType intentType;
  final bool isCompact;

  const IntentChip({
    super.key,
    required this.intentType,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.intentColor(intentType.value);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            intentType.emoji,
            style: TextStyle(fontSize: isCompact ? 10 : 12),
          ),
          SizedBox(width: isCompact ? 3 : 5),
          Text(
            intentType.displayName,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

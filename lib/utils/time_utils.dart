import 'package:intl/intl.dart';

/// Time utility functions for the app
class TimeUtils {
  TimeUtils._();

  /// Format a duration as "Xh Ym" or "Ym" or "Xs"
  static String formatDuration(Duration duration) {
    if (duration.isNegative) return 'Expired';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Format a duration as compact string for timer badge
  static String formatTimerCompact(Duration duration) {
    if (duration.isNegative) return '0:00';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final mins = duration.inMinutes.remainder(60);
      return '$hours:${mins.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format a datetime as relative time ("2m ago", "1h ago", "just now")
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('MMM d').format(dateTime);
  }

  /// Format time as "3:45 PM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}

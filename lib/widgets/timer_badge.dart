import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/time_utils.dart';

/// Countdown timer badge — changes color as time runs low
class TimerBadge extends StatefulWidget {
  final DateTime expiresAt;
  final bool isCompact;

  const TimerBadge({
    super.key,
    required this.expiresAt,
    this.isCompact = false,
  });

  @override
  State<TimerBadge> createState() => _TimerBadgeState();
}

class _TimerBadgeState extends State<TimerBadge> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.expiresAt.difference(now);
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color get _timerColor {
    if (_remaining.inMinutes > 30) return AppTheme.success;
    if (_remaining.inMinutes > 10) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final timeText = TimeUtils.formatTimerCompact(_remaining);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 6 : 10,
        vertical: widget.isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _timerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: widget.isCompact ? 12 : 14,
            color: _timerColor,
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              color: _timerColor,
              fontSize: widget.isCompact ? 11 : 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

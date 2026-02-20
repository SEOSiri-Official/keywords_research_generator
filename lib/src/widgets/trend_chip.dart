import 'package:flutter/material.dart';

/// Displays a trend direction chip with color coding.
///
/// Uses real data from the GoogleTrendsService.
class TrendChip extends StatelessWidget {
  final int direction; // 1 rising, 0 stable, -1 declining
  final int? interestScore;
  final bool compact;

  const TrendChip({
    super.key,
    required this.direction,
    this.interestScore,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (direction) {
      1 => ('📈', 'Rising', const Color(0xFF4CAF50)),
      -1 => ('📉', 'Declining', const Color(0xFFF44336)),
      _ => ('➡️', 'Stable', const Color(0xFF9E9E9E)),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: compact ? 10 : 12)),
          const SizedBox(width: 4),
          Text(
            compact
                ? label
                : interestScore != null
                    ? '$label ($interestScore/100)'
                    : label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
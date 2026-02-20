import 'package:flutter/material.dart';
import '../models/search_intent.dart';

/// A small colored badge displaying the search intent of a keyword.
class IntentBadge extends StatelessWidget {
  final SearchIntent intent;
  final bool compact;

  const IntentBadge({
    super.key,
    required this.intent,
    this.compact = false,
  });

  static Color colorFor(SearchIntent intent) => switch (intent) {
        SearchIntent.informational => const Color(0xFF2196F3), // blue
        SearchIntent.navigational => const Color(0xFF9C27B0),  // purple
        SearchIntent.commercial => const Color(0xFFFF9800),    // orange
        SearchIntent.transactional => const Color(0xFF4CAF50), // green
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(intent);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            intent.emoji,
            style: TextStyle(fontSize: compact ? 10 : 13),
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              intent.label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
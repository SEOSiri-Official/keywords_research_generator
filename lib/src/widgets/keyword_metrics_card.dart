import 'package:flutter/material.dart';
import '../models/keyword_model.dart';
import '../models/keyword_type.dart';
import 'intent_badge.dart';

/// Displays full metrics and hints for a single [KeywordModel].
class KeywordMetricsCard extends StatelessWidget {
  final KeywordModel keyword;
  final VoidCallback? onTap;

  const KeywordMetricsCard({
    super.key,
    required this.keyword,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = keyword.metrics;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ Header row ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      keyword.phrase,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IntentBadge(intent: keyword.intent),
                ],
              ),
              const SizedBox(height: 8),

              // ─ Type + tags row ─────────────────────────────────────────────
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _tag(
                    keyword.keywordType.label,
                    _tailColor(keyword.keywordType),
                  ),
                  if (m.isVoiceSearchFriendly)
                    _tag('🎙 Voice', Colors.teal),
                  if (m.isAeoFriendly)
                    _tag('⚡ AEO', Colors.deepPurple),
                  if (m.trendDirection == 1)
                    _tag('📈 Trending', Colors.green),
                  if (keyword.region != null)
                    _tag('📍 ${keyword.region}', Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 12),

              // ─ Metrics grid ────────────────────────────────────────────────
              Row(
                children: [
                  _metricTile('Volume',
                      _formatVolume(m.estimatedMonthlySearches), context),
                  _metricTile(
                      'SEO Diff', '${m.seoDifficulty}/100', context,
                      valueColor: _difficultyColor(m.seoDifficulty)),
                  _metricTile('CPC', '\$${m.estimatedCpc.toStringAsFixed(2)}',
                      context),
                  _metricTile(
                      'Opportunity', '${m.opportunityScore}/100', context,
                      valueColor: _opportunityColor(m.opportunityScore)),
                ],
              ),

              // ─ Opportunity bar ─────────────────────────────────────────────
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: m.opportunityScore / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: _opportunityColor(m.opportunityScore),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, BuildContext context,
      {Color? valueColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      );

  Color _tailColor(KeywordType type) => switch (type) {
        KeywordType.shortTail => Colors.red.shade400,
        KeywordType.mediumTail => Colors.orange.shade600,
        KeywordType.longTail => Colors.green.shade600,
      };

  Color _difficultyColor(int d) {
    if (d >= 70) return Colors.red;
    if (d >= 40) return Colors.orange;
    return Colors.green;
  }

  Color _opportunityColor(int s) {
    if (s >= 70) return Colors.green;
    if (s >= 40) return Colors.orange;
    return Colors.red.shade300;
  }

  String _formatVolume(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }
}
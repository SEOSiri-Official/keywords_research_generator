import 'package:flutter/material.dart';
import '../services/pipeline/keyword_cluster_builder.dart';
import '../models/keyword_model.dart';
import 'intent_badge.dart';

/// Displays keyword topic clusters in a visual card layout.
///
/// Each cluster shows a pillar keyword + its supporting keywords.
/// Includes volume, difficulty, and intent breakdown.
class KeywordClusterWidget extends StatelessWidget {
  final List<ClusterSummary> clusters;
  final void Function(KeywordModel keyword)? onKeywordTap;

  const KeywordClusterWidget({
    super.key,
    required this.clusters,
    this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (clusters.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No clusters yet. Generate keywords first.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: clusters.length,
      itemBuilder: (ctx, i) => _ClusterCard(
        cluster: clusters[i],
        onKeywordTap: onKeywordTap,
        clusterIndex: i,
      ),
    );
  }
}

class _ClusterCard extends StatefulWidget {
  final ClusterSummary cluster;
  final void Function(KeywordModel)? onKeywordTap;
  final int clusterIndex;

  const _ClusterCard({
    required this.cluster,
    this.onKeywordTap,
    required this.clusterIndex,
  });

  @override
  State<_ClusterCard> createState() => _ClusterCardState();
}

class _ClusterCardState extends State<_ClusterCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cluster = widget.cluster;
    final colors = [
      Colors.blue, Colors.purple, Colors.teal, Colors.orange,
      Colors.pink, Colors.indigo, Colors.green, Colors.red,
    ];
    final color = colors[widget.clusterIndex % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Cluster header ──────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(14))
                    : BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${widget.clusterIndex + 1}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cluster.pillarPhrase,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${cluster.clusterSize} keywords · ${cluster.volumeLabel} est. volume',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IntentBadge(intent: cluster.pillar.intent, compact: true),
                      const SizedBox(width: 6),
                      _statChip(
                          'Difficulty: ${cluster.averageDifficulty}/100',
                          _diffColor(cluster.averageDifficulty)),
                      const SizedBox(width: 6),
                      _statChip(
                          '${cluster.clusterSize} terms', Colors.blueGrey),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─ Supporting keywords ─────────────────────────────────────────
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pillar keyword
                  _KeywordRow(
                    keyword: cluster.pillar,
                    isPillar: true,
                    accentColor: color,
                    onTap: () => widget.onKeywordTap?.call(cluster.pillar),
                  ),
                  const Divider(height: 16),
                  // Supporting keywords
                  ...cluster.supportingKeywords
                      .take(8)
                      .map((kw) => _KeywordRow(
                            keyword: kw,
                            accentColor: color,
                            onTap: () => widget.onKeywordTap?.call(kw),
                          )),
                  if (cluster.supportingKeywords.length > 8)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '+${cluster.supportingKeywords.length - 8} more keywords in this cluster',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600),
        ),
      );

  Color _diffColor(int d) {
    if (d >= 70) return Colors.red;
    if (d >= 40) return Colors.orange;
    return Colors.green;
  }
}

class _KeywordRow extends StatelessWidget {
  final KeywordModel keyword;
  final bool isPillar;
  final Color accentColor;
  final VoidCallback? onTap;

  const _KeywordRow({
    required this.keyword,
    this.isPillar = false,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final m = keyword.metrics;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Row(
          children: [
            if (isPillar)
              Icon(Icons.star_rounded, color: accentColor, size: 14)
            else
              Icon(Icons.subdirectory_arrow_right,
                  color: Colors.grey.shade400, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                keyword.phrase,
                style: TextStyle(
                  fontSize: isPillar ? 13 : 12,
                  fontWeight:
                      isPillar ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              _formatVol(m.estimatedMonthlySearches),
              style: const TextStyle(
                  fontSize: 11, color: Colors.blue),
            ),
            const SizedBox(width: 8),
            Text(
              'D:${m.seoDifficulty}',
              style: TextStyle(
                  fontSize: 11, color: _diffColor(m.seoDifficulty)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatVol(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  Color _diffColor(int d) {
    if (d >= 70) return Colors.red;
    if (d >= 40) return Colors.orange;
    return Colors.green;
  }
}

import '../../models/keyword_model.dart';
import '../../models/search_intent.dart';

/// Groups keywords into semantic topic clusters using local string similarity.
///
/// No external API needed — runs entirely in Dart.
/// Strategy: keywords sharing a common root word or semantic prefix
/// are grouped. Each group gets a pillar keyword + supporting cluster terms.
class KeywordClusterBuilder {
  /// Clusters [keywords] into topic groups.
  ///
  /// Returns a map where:
  /// - Key = pillar keyword (highest opportunity score in group)
  /// - Value = list of cluster/supporting keywords
  Map<KeywordModel, List<KeywordModel>> buildClusters(
    List<KeywordModel> keywords, {
    int minClusterSize = 2,
  }) {
    if (keywords.isEmpty) return {};

    final clusters = <String, List<KeywordModel>>{};

    for (final kw in keywords) {
      final root = _extractRoot(kw.phrase);
      clusters.putIfAbsent(root, () => []).add(kw);
    }

    // Select the pillar (highest opportunity) for each cluster.
    final result = <KeywordModel, List<KeywordModel>>{};

    for (final entry in clusters.entries) {
      if (entry.value.length < minClusterSize) continue;

      final sorted = List<KeywordModel>.from(entry.value)
        ..sort((a, b) =>
            b.metrics.opportunityScore.compareTo(a.metrics.opportunityScore));

      final pillar = sorted.first;
      final supporting = sorted.sublist(1);
      result[pillar] = supporting;
    }

    return result;
  }

  /// Returns cluster summary stats for display.
  List<ClusterSummary> summarize(Map<KeywordModel, List<KeywordModel>> clusters) {
    final summaries = <ClusterSummary>[];
    for (final entry in clusters.entries) {
      final KeywordModel pillar = entry.key;
      final List<KeywordModel> supporting = entry.value;
      final all = <KeywordModel>[pillar, ...supporting];

      int totalVolume = 0;
      int totalDifficulty = 0;
      for (final k in all) {
        totalVolume += k.metrics.estimatedMonthlySearches;
        totalDifficulty += k.metrics.seoDifficulty;
      }
      final int avgDifficulty = totalDifficulty ~/ all.length;
      final intents = all.map((k) => k.intent).toSet();

      summaries.add(ClusterSummary(
        pillar: pillar,
        supportingKeywords: supporting,
        totalEstimatedVolume: totalVolume,
        averageDifficulty: avgDifficulty,
        intents: intents,
        clusterSize: all.length,
      ));
    }
    summaries.sort((a, b) =>
        b.totalEstimatedVolume.compareTo(a.totalEstimatedVolume));
    return summaries;
  }

  // ─── Root Extraction ──────────────────────────────────────────────────────

  /// Extracts a semantic root from a phrase for grouping purposes.
  ///
  /// Strategy:
  /// 1. Strip common stop words
  /// 2. Take the first 1–2 meaningful content words
  String _extractRoot(String phrase) {
    final words = phrase
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toList();

    if (words.isEmpty) return phrase.toLowerCase().trim();
    if (words.length == 1) return words.first;

    // Use first two meaningful words as cluster root.
    return '${words[0]} ${words[1]}';
  }

  static const _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'for', 'nor', 'so',
    'yet', 'at', 'by', 'in', 'of', 'on', 'to', 'up', 'as', 'is',
    'it', 'its', 'be', 'has', 'had', 'was', 'are', 'were', 'been',
    'have', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
    'may', 'might', 'shall', 'can', 'this', 'that', 'these', 'those',
    'what', 'which', 'who', 'how', 'when', 'where', 'why', 'with',
    'from', 'into', 'through', 'during', 'before', 'after', 'about',
    'not', 'no', 'your', 'my', 'our', 'their',
  };
}

/// Summary of a keyword cluster for display and reporting.
class ClusterSummary {
  final KeywordModel pillar;
  final List<KeywordModel> supportingKeywords;
  final int totalEstimatedVolume;
  final int averageDifficulty;
  final Set<SearchIntent> intents;
  final int clusterSize;

  const ClusterSummary({
    required this.pillar,
    required this.supportingKeywords,
    required this.totalEstimatedVolume,
    required this.averageDifficulty,
    required this.intents,
    required this.clusterSize,
  });

  String get volumeLabel {
    if (totalEstimatedVolume >= 1000000) {
      return '${(totalEstimatedVolume / 1000000).toStringAsFixed(1)}M';
    }
    if (totalEstimatedVolume >= 1000) {
      return '${(totalEstimatedVolume / 1000).toStringAsFixed(1)}K';
    }
    return '$totalEstimatedVolume';
  }

  String get pillarPhrase => pillar.phrase;
}

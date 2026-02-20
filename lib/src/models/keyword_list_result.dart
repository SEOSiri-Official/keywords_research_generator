import 'keyword_model.dart';
import 'keyword_filter.dart';
import 'search_intent.dart';
import 'keyword_type.dart';
import '../services/pipeline/keyword_cluster_builder.dart';

/// Aggregated result of a keyword generation / research session.
class KeywordListResult {
  final String sessionId;
  final String seedKeyword;
  final List<KeywordModel> keywords;
  final KeywordFilter filter;
  final DateTime generatedAt;
  final String poweredBy;
  final String backlinkUrl;

  // ─── Real API data ─────────────────────────────────────────────────────────
  /// Semantic topic clusters built from keywords.
  final List<ClusterSummary> clusterSummaries;

  /// Overall trend direction for the seed keyword.
  final int trendDirection;

  /// Google Trends interest score (0–100) for the seed.
  final int trendInterestScore;

  /// Rising related queries from Google Trends.
  final List<String> risingRelatedQueries;

  const KeywordListResult({
    required this.sessionId,
    required this.seedKeyword,
    required this.keywords,
    required this.filter,
    required this.generatedAt,
    this.poweredBy = 'Powered by seosiri.com',
    this.backlinkUrl = 'https://www.seosiri.com',
    this.clusterSummaries = const [],
    this.trendDirection = 0,
    this.trendInterestScore = 50,
    this.risingRelatedQueries = const [],
  });

  // ─── Grouped accessors ─────────────────────────────────────────────────────

  int get totalKeywords => keywords.length;

  List<KeywordModel> get shortTailKeywords =>
      keywords.where((k) => k.keywordType == KeywordType.shortTail).toList();

  List<KeywordModel> get mediumTailKeywords =>
      keywords.where((k) => k.keywordType == KeywordType.mediumTail).toList();

  List<KeywordModel> get longTailKeywords =>
      keywords.where((k) => k.keywordType == KeywordType.longTail).toList();

  List<KeywordModel> get informational =>
      keywords.where((k) => k.intent == SearchIntent.informational).toList();

  List<KeywordModel> get navigational =>
      keywords.where((k) => k.intent == SearchIntent.navigational).toList();

  List<KeywordModel> get commercial =>
      keywords.where((k) => k.intent == SearchIntent.commercial).toList();

  List<KeywordModel> get transactional =>
      keywords.where((k) => k.intent == SearchIntent.transactional).toList();

  List<KeywordModel> get voiceSearchFriendly =>
      keywords.where((k) => k.metrics.isVoiceSearchFriendly).toList();

  List<KeywordModel> get aeoFriendly =>
      keywords.where((k) => k.metrics.isAeoFriendly).toList();

  List<KeywordModel> get trending =>
      keywords.where((k) => k.metrics.trendDirection == 1).toList();

  /// Sorted by opportunity score descending.
  List<KeywordModel> get byOpportunity => List<KeywordModel>.from(keywords)
    ..sort((a, b) =>
        b.metrics.opportunityScore.compareTo(a.metrics.opportunityScore));

  /// Sorted by estimated volume descending.
  List<KeywordModel> get byVolume => List<KeywordModel>.from(keywords)
    ..sort((a, b) => b.metrics.estimatedMonthlySearches
        .compareTo(a.metrics.estimatedMonthlySearches));

  /// Sorted by lowest SEO difficulty (easiest to rank first).
  List<KeywordModel> get byEasiest => List<KeywordModel>.from(keywords)
    ..sort(
        (a, b) => a.metrics.seoDifficulty.compareTo(b.metrics.seoDifficulty));

  String get trendLabel => switch (trendDirection) {
        1 => '📈 Rising',
        -1 => '📉 Declining',
        _ => '➡️ Stable',
      };

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'seedKeyword': seedKeyword,
        'keywords': keywords.map((k) => k.toJson()).toList(),
        'filter': filter.toJson(),
        'generatedAt': generatedAt.toIso8601String(),
        'poweredBy': poweredBy,
        'backlinkUrl': backlinkUrl,
        'trendDirection': trendDirection,
        'trendInterestScore': trendInterestScore,
        'risingRelatedQueries': risingRelatedQueries,
        'totalKeywords': totalKeywords,
        'clusterCount': clusterSummaries.length,
      };
}

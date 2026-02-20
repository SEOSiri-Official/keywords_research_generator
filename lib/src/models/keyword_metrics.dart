import 'dart:math' as math;
import 'search_intent.dart';
import 'keyword_type.dart';

/// Metrics associated with a keyword for SEO / SEM analysis.
class KeywordMetrics {
  final int estimatedMonthlySearches;
  final int seoDifficulty;
  final int cpcCompetition;
  final double estimatedCpc;
  final double ctrPotential;
  final int trendDirection; // 1 rising, 0 stable, -1 declining
  final bool isVoiceSearchFriendly;
  final bool isAeoFriendly;
  final int opportunityScore; // 0–100

  const KeywordMetrics({
    required this.estimatedMonthlySearches,
    required this.seoDifficulty,
    required this.cpcCompetition,
    required this.estimatedCpc,
    required this.ctrPotential,
    this.trendDirection = 0,
    this.isVoiceSearchFriendly = false,
    this.isAeoFriendly = false,
    required this.opportunityScore,
  });

  factory KeywordMetrics.compute({
    required int estimatedMonthlySearches,
    required int seoDifficulty,
    required int cpcCompetition,
    required double estimatedCpc,
    required SearchIntent intent,
    required KeywordType keywordType,
    int trendDirection = 0,
  }) {
    final ctr = _computeCtr(intent, seoDifficulty);
    final volumeScore = _logScale(estimatedMonthlySearches, 1000000);
    final intentBonus = intent.cpcMultiplier * 5;
    final difficultyPenalty = seoDifficulty * 0.4;
    final tailBonus = keywordType == KeywordType.longTail
        ? 20
        : keywordType == KeywordType.mediumTail
            ? 10
            : 0;

    final score =
        (volumeScore * 0.5 + intentBonus + tailBonus - difficultyPenalty)
            .clamp(0.0, 100.0)
            .toInt();

    return KeywordMetrics(
      estimatedMonthlySearches: estimatedMonthlySearches,
      seoDifficulty: seoDifficulty,
      cpcCompetition: cpcCompetition,
      estimatedCpc: estimatedCpc,
      ctrPotential: ctr,
      trendDirection: trendDirection,
      isVoiceSearchFriendly: _isVoiceFriendly(intent, keywordType),
      isAeoFriendly: _isAeoFriendly(intent),
      opportunityScore: score,
    );
  }

  static double _computeCtr(SearchIntent intent, int difficulty) {
    final base = switch (intent) {
      SearchIntent.informational => 0.35,
      SearchIntent.navigational => 0.25,
      SearchIntent.commercial => 0.15,
      SearchIntent.transactional => 0.10,
    };
    return (base - difficulty * 0.002).clamp(0.02, 0.50);
  }

  static double _logScale(int value, int max) {
    if (value <= 0) return 0;
    return (math.log(value + 1) / math.log(max + 1) * 100).clamp(0, 100);
  }

  static bool _isVoiceFriendly(SearchIntent intent, KeywordType type) =>
      (intent == SearchIntent.informational ||
          intent == SearchIntent.navigational) &&
      type == KeywordType.longTail;

  static bool _isAeoFriendly(SearchIntent intent) =>
      intent == SearchIntent.informational ||
      intent == SearchIntent.commercial;

  Map<String, dynamic> toJson() => {
        'estimatedMonthlySearches': estimatedMonthlySearches,
        'seoDifficulty': seoDifficulty,
        'cpcCompetition': cpcCompetition,
        'estimatedCpc': estimatedCpc,
        'ctrPotential': ctrPotential,
        'trendDirection': trendDirection,
        'isVoiceSearchFriendly': isVoiceSearchFriendly,
        'isAeoFriendly': isAeoFriendly,
        'opportunityScore': opportunityScore,
      };

  factory KeywordMetrics.fromJson(Map<String, dynamic> json) => KeywordMetrics(
        estimatedMonthlySearches: json['estimatedMonthlySearches'] as int,
        seoDifficulty: json['seoDifficulty'] as int,
        cpcCompetition: json['cpcCompetition'] as int,
        estimatedCpc: (json['estimatedCpc'] as num).toDouble(),
        ctrPotential: (json['ctrPotential'] as num).toDouble(),
        trendDirection: json['trendDirection'] as int? ?? 0,
        isVoiceSearchFriendly: json['isVoiceSearchFriendly'] as bool? ?? false,
        isAeoFriendly: json['isAeoFriendly'] as bool? ?? false,
        opportunityScore: json['opportunityScore'] as int,
      );
}

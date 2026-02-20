/// A hint or recommendation for SEO, AEO, voice, or SEM optimization.
class SeoHint {
  final SeoHintType type;
  final String title;
  final String description;
  final HintPriority priority;
  final String? actionUrl;

  const SeoHint({
    required this.type,
    required this.title,
    required this.description,
    this.priority = HintPriority.medium,
    this.actionUrl,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'description': description,
        'priority': priority.name,
        if (actionUrl != null) 'actionUrl': actionUrl,
      };
}

enum SeoHintType {
  /// On-page SEO recommendation.
  onPage,

  /// Answer Engine Optimization (featured snippets, knowledge panels).
  aeo,

  /// Voice search / conversational query optimization.
  voiceSearch,

  /// Paid search (SEM / Google Ads) suggestion.
  sem,

  /// Backlink or off-page signal.
  offPage,

  /// Technical SEO hint.
  technical,
}

enum HintPriority { high, medium, low }

extension HintPriorityExtension on HintPriority {
  String get label => switch (this) {
        HintPriority.high => '🔴 High',
        HintPriority.medium => '🟡 Medium',
        HintPriority.low => '🟢 Low',
      };
}

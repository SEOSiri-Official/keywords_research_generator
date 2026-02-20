/// Search intent classification for keywords.
///
/// Based on the four core search intent types used in SEO strategy.
enum SearchIntent {
  /// User seeks to learn or understand something.
  /// e.g. "what is flutter", "how to do SEO"
  informational,

  /// User wants to reach a specific website or resource.
  /// e.g. "pub.dev flutter", "seosiri keyword tool"
  navigational,

  /// User is researching before making a purchase decision.
  /// e.g. "best keyword research tools", "flutter vs react native"
  commercial,

  /// User is ready to take action (buy, sign up, download).
  /// e.g. "buy keyword tool", "download flutter", "subscribe seo tool"
  transactional,
}

extension SearchIntentExtension on SearchIntent {
  String get label {
    switch (this) {
      case SearchIntent.informational:
        return 'Informational';
      case SearchIntent.navigational:
        return 'Navigational';
      case SearchIntent.commercial:
        return 'Commercial';
      case SearchIntent.transactional:
        return 'Transactional';
    }
  }

  String get description {
    switch (this) {
      case SearchIntent.informational:
        return 'User wants to learn or find information';
      case SearchIntent.navigational:
        return 'User is looking for a specific website or page';
      case SearchIntent.commercial:
        return 'User is researching products or services';
      case SearchIntent.transactional:
        return 'User intends to take an action or make a purchase';
    }
  }

  String get emoji {
    switch (this) {
      case SearchIntent.informational:
        return '📚';
      case SearchIntent.navigational:
        return '🧭';
      case SearchIntent.commercial:
        return '🛒';
      case SearchIntent.transactional:
        return '💳';
    }
  }

  /// Typical CPC multiplier relative to informational keywords.
  double get cpcMultiplier {
    switch (this) {
      case SearchIntent.informational:
        return 1.0;
      case SearchIntent.navigational:
        return 1.5;
      case SearchIntent.commercial:
        return 3.0;
      case SearchIntent.transactional:
        return 5.0;
    }
  }
}

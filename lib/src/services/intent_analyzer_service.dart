import '../models/search_intent.dart';

/// Analyses a keyword phrase and classifies its search intent.
///
/// Uses rule-based heuristics with weighted signals. For production use
/// combine with an LLM API (e.g. Anthropic) for richer classification.
class IntentAnalyzerService {
  // ─── Signal word lists ─────────────────────────────────────────────────────

  static const _informationalSignals = [
    'what', 'how', 'why', 'when', 'where', 'who', 'which',
    'guide', 'tutorial', 'learn', 'understand', 'explain',
    'definition', 'meaning', 'example', 'tips', 'ideas',
    'ways to', 'how to', 'what is', 'what are',
  ];

  static const _navigationalSignals = [
    'login', 'sign in', 'official', 'website', 'site',
    'homepage', 'dashboard', 'account', 'portal', 'app',
    'download', 'install', 'pub.dev', 'github', 'docs',
  ];

  static const _commercialSignals = [
    'best', 'top', 'review', 'vs', 'versus', 'compare',
    'alternative', 'pros cons', 'worth', 'recommend',
    'cheapest', 'affordable', 'free', 'premium', 'plan',
    'pricing', 'cost', 'price',
  ];

  static const _transactionalSignals = [
    'buy', 'purchase', 'order', 'subscribe', 'get', 'hire',
    'download', 'sign up', 'register', 'book', 'reserve',
    'try', 'free trial', 'coupon', 'discount', 'deal', 'offer',
    'promo', 'checkout', 'add to cart',
  ];

  /// Classifies the [phrase] into a [SearchIntent].
  SearchIntent classify(String phrase) {
    final lower = phrase.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));

    int infoScore = 0;
    int navScore = 0;
    int commScore = 0;
    int transScore = 0;

    void score(List<String> signals, void Function(int) add) {
      for (final signal in signals) {
        if (lower.contains(signal)) add(signal.split(' ').length);
      }
    }

    score(_informationalSignals, (s) => infoScore += s);
    score(_navigationalSignals, (s) => navScore += s);
    score(_commercialSignals, (s) => commScore += s);
    score(_transactionalSignals, (s) => transScore += s);

    // Presence of question mark strongly suggests informational.
    if (phrase.contains('?')) infoScore += 3;

    // Short phrases with brand-like words → navigational.
    if (words.length <= 2 && navScore > 0) navScore += 5;

    final max = [infoScore, navScore, commScore, transScore].reduce(
        (a, b) => a > b ? a : b);

    if (max == 0) {
      // Default: informational for vague phrases.
      return SearchIntent.informational;
    }
    if (transScore == max) return SearchIntent.transactional;
    if (commScore == max) return SearchIntent.commercial;
    if (navScore == max) return SearchIntent.navigational;
    return SearchIntent.informational;
  }

  /// Returns all four intent scores for a phrase (useful for UI).
  Map<SearchIntent, int> scoreAll(String phrase) {
    final lower = phrase.toLowerCase();
    int infoScore = 0, navScore = 0, commScore = 0, transScore = 0;

    for (final s in _informationalSignals) {
      if (lower.contains(s)) infoScore += s.split(' ').length;
    }
    for (final s in _navigationalSignals) {
      if (lower.contains(s)) navScore += s.split(' ').length;
    }
    for (final s in _commercialSignals) {
      if (lower.contains(s)) commScore += s.split(' ').length;
    }
    for (final s in _transactionalSignals) {
      if (lower.contains(s)) transScore += s.split(' ').length;
    }

    if (phrase.contains('?')) infoScore += 3;

    return {
      SearchIntent.informational: infoScore,
      SearchIntent.navigational: navScore,
      SearchIntent.commercial: commScore,
      SearchIntent.transactional: transScore,
    };
  }
}

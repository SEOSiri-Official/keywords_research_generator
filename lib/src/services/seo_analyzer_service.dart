import '../models/keyword_model.dart';
import '../models/seo_hint.dart';
import '../models/search_intent.dart';
import '../models/keyword_type.dart';

/// Analyses keywords and produces actionable SEO, AEO, and ranking hints.
class SeoAnalyzerService {
  /// Generates a list of [SeoHint] recommendations for a [keyword].
  List<SeoHint> analyzeKeyword(KeywordModel keyword) {
    final hints = <SeoHint>[];

    hints.addAll(_onPageHints(keyword));
    hints.addAll(_aeoHints(keyword));
    hints.addAll(_voiceHints(keyword));
    hints.addAll(_rankingHints(keyword));

    return hints;
  }

  List<SeoHint> _onPageHints(KeywordModel keyword) {
    final hints = <SeoHint>[];
    final phrase = keyword.phrase;
    final difficulty = keyword.metrics.seoDifficulty;

    if (difficulty > 70) {
      hints.add(SeoHint(
        type: SeoHintType.onPage,
        title: 'High competition — focus on long-tail variants',
        description:
            '"$phrase" has difficulty $difficulty/100. Target longer, '
            'more specific variants to get early traction.',
        priority: HintPriority.high,
      ));
    }

    if (keyword.keywordType == KeywordType.shortTail) {
      hints.add(const SeoHint(
        type: SeoHintType.onPage,
        title: 'Use as H1/Title anchor',
        description:
            'Short-tail keywords work best as page titles, H1 headings, '
            'and meta descriptions. Pair with long-tail variations in body content.',
        priority: HintPriority.medium,
      ));
    }

    if (keyword.intent == SearchIntent.informational) {
      hints.add(const SeoHint(
        type: SeoHintType.onPage,
        title: 'Create a comprehensive content piece',
        description:
            'Informational intent: write a 1500–3000 word article, '
            'FAQ section, or guide that answers related questions.',
        priority: HintPriority.medium,
      ));
    }

    if (keyword.intent == SearchIntent.transactional) {
      hints.add(const SeoHint(
        type: SeoHintType.onPage,
        title: 'Optimise landing or product page',
        description:
            'Transactional intent: ensure a clear CTA, trust signals, '
            'schema markup (Product, Offer), and fast page load.',
        priority: HintPriority.high,
      ));
    }

    return hints;
  }

  List<SeoHint> _aeoHints(KeywordModel keyword) {
    if (!keyword.metrics.isAeoFriendly) return [];

    return [
      const SeoHint(
        type: SeoHintType.aeo,
        title: 'Target featured snippet with structured answer',
        description:
            'Format your content with: a 40–60 word direct answer paragraph, '
            'followed by ordered/unordered lists and tables. Use the exact query '
            'phrase in an H2.',
        priority: HintPriority.high,
        actionUrl: 'https://www.seosiri.com/aeo-guide',
      ),
      const SeoHint(
        type: SeoHintType.aeo,
        title: 'Add FAQ schema markup',
        description:
            'Add FAQPage JSON-LD schema to your page. Google may show your '
            'answers in the People Also Ask (PAA) box.',
        priority: HintPriority.medium,
      ),
    ];
  }

  List<SeoHint> _voiceHints(KeywordModel keyword) {
    if (!keyword.metrics.isVoiceSearchFriendly) return [];

    return [
      const SeoHint(
        type: SeoHintType.voiceSearch,
        title: 'Optimise for conversational queries',
        description:
            'Use natural language in headings. Answer who, what, where, '
            'when, why, how. Keep answers concise (under 30 words for voice).',
        priority: HintPriority.medium,
        actionUrl: 'https://www.seosiri.com/voice-seo',
      ),
      SeoHint(
        type: SeoHintType.voiceSearch,
        title: 'Claim Google Business Profile',
        description:
            '"Near me" voice queries rely heavily on local listings. '
            'Ensure your GBP is complete with address, hours, and photos.',
        priority: keyword.region != null ? HintPriority.high : HintPriority.low,
      ),
    ];
  }

  List<SeoHint> _rankingHints(KeywordModel keyword) {
    final hints = <SeoHint>[];
    final score = keyword.metrics.opportunityScore;

    if (score >= 70) {
      hints.add(SeoHint(
        type: SeoHintType.onPage,
        title: 'High-opportunity keyword — prioritise now',
        description:
            'Opportunity score $score/100. Publish and promote content '
            'targeting this keyword within the next sprint.',
        priority: HintPriority.high,
      ));
    }

    if (keyword.metrics.trendDirection == 1) {
      hints.add(const SeoHint(
        type: SeoHintType.onPage,
        title: 'Trending keyword — act early',
        description:
            'This keyword shows rising search interest. Publishing '
            'now can establish topical authority before competition grows.',
        priority: HintPriority.high,
      ));
    }

    return hints;
  }
}
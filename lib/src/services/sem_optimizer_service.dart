import '../models/keyword_model.dart';
import '../models/seo_hint.dart';
import '../models/search_intent.dart';
import '../models/keyword_type.dart';

/// Provides SEM (Search Engine Marketing / Google Ads) optimisation hints.
class SemOptimizerService {
  /// Returns SEM hints for a given [keyword].
  List<SeoHint> generateSemHints(KeywordModel keyword) {
    final hints = <SeoHint>[];

    hints.add(_bidStrategyHint(keyword));
    hints.addAll(_adGroupHints(keyword));
    hints.add(_matchTypeHint(keyword));
    hints.add(_adCopyHint(keyword));
    hints.add(_landingPageHint(keyword));

    return hints;
  }

  SeoHint _bidStrategyHint(KeywordModel keyword) {
    final cpc = keyword.metrics.estimatedCpc;
    final competition = keyword.metrics.cpcCompetition;
    String desc;
    HintPriority priority;

    if (competition > 70) {
      desc = 'High CPC competition (~\$${cpc.toStringAsFixed(2)}/click). '
          'Use Target CPA bidding and set tight audience segments to maximise ROI.';
      priority = HintPriority.high;
    } else if (competition > 40) {
      desc = 'Moderate CPC (~\$${cpc.toStringAsFixed(2)}/click). '
          'Enhanced CPC or Maximize Conversions is recommended.';
      priority = HintPriority.medium;
    } else {
      desc = 'Low CPC (~\$${cpc.toStringAsFixed(2)}/click). '
          'Good opportunity for budget-efficient testing with Manual CPC.';
      priority = HintPriority.low;
    }

    return SeoHint(
      type: SeoHintType.sem,
      title: 'Bid strategy recommendation',
      description: desc,
      priority: priority,
    );
  }

  List<SeoHint> _adGroupHints(KeywordModel keyword) {
    final hints = <SeoHint>[];

    if (keyword.businessSegment != null) {
      hints.add(SeoHint(
        type: SeoHintType.sem,
        title: 'Segment ad group by: ${keyword.businessSegment}',
        description:
            'Group this keyword with similar ${keyword.businessSegment} '
            'terms to keep Quality Score high and ad relevance tight.',
        priority: HintPriority.medium,
      ));
    }

    if (keyword.region != null) {
      hints.add(SeoHint(
        type: SeoHintType.sem,
        title: 'Geo-target: ${keyword.region}',
        description:
            'Restrict this campaign to the "${keyword.region}" region '
            'to improve relevance and reduce wasted spend.',
        priority: HintPriority.medium,
      ));
    }

    return hints;
  }

  SeoHint _matchTypeHint(KeywordModel keyword) {
    final type = keyword.keywordType;
    final matchType = switch (type) {
      KeywordType.shortTail => 'Phrase Match or Broad Match Modifier',
      KeywordType.mediumTail => 'Phrase Match',
      KeywordType.longTail => 'Exact Match',
    };
    return SeoHint(
      type: SeoHintType.sem,
      title: 'Recommended match type: $matchType',
      description:
          '${type.label} keywords perform best with $matchType in Google Ads '
          'to balance reach and relevance.',
      priority: HintPriority.medium,
    );
  }

  SeoHint _adCopyHint(KeywordModel keyword) {
    final intent = keyword.intent;
    final adAngle = switch (intent) {
      SearchIntent.informational =>
        'Lead with education: "Learn how to…", "Complete guide to…"',
      SearchIntent.navigational =>
        'Use brand name prominently; include your URL in ad text.',
      SearchIntent.commercial =>
        'Highlight proof: "Rated #1", "Trusted by X users", comparison angle.',
      SearchIntent.transactional =>
        'Drive action: "Get started free", "Buy now – 20% off", limited-time offer.',
    };
    return SeoHint(
      type: SeoHintType.sem,
      title: 'Ad copy angle for ${intent.label} intent',
      description: adAngle,
      priority: HintPriority.high,
    );
  }

  SeoHint _landingPageHint(KeywordModel keyword) {
    return SeoHint(
      type: SeoHintType.sem,
      title: 'Landing page alignment',
      description:
          'Ensure the landing page title, H1, and first paragraph all '
          'include the exact phrase "${keyword.phrase}". '
          'Mismatched pages lower Quality Score and raise CPC.',
      priority: HintPriority.high,
      actionUrl: 'https://www.seosiri.com/sem-landing-pages',
    );
  }

  /// Returns keywords sorted by best SEM ROI potential.
  List<KeywordModel> rankBySemPotential(List<KeywordModel> keywords) {
    final ranked = List<KeywordModel>.from(keywords);
    ranked.sort((a, b) {
      // Higher opportunity score + higher transactional intent = better SEM ROI.
      final aScore = a.metrics.opportunityScore +
          (a.intent == SearchIntent.transactional ? 30 : 0) +
          (a.intent == SearchIntent.commercial ? 15 : 0);
      final bScore = b.metrics.opportunityScore +
          (b.intent == SearchIntent.transactional ? 30 : 0) +
          (b.intent == SearchIntent.commercial ? 15 : 0);
      return bScore.compareTo(aScore);
    });
    return ranked;
  }
}

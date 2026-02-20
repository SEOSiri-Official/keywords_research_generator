import 'search_intent.dart';
import 'keyword_type.dart';

/// Filter parameters for keyword generation and search.
class KeywordFilter {
  /// Target business segment (e.g. "E-commerce", "SaaS", "Healthcare").
  final String? businessSegment;

  /// Target geographic region (e.g. "US", "UK", "BD", "Global").
  final String? region;

  /// Content or product category (e.g. "Flutter", "SEO Tools", "Finance").
  final String? category;

  /// Restrict results to specific search intents.
  final List<SearchIntent>? intents;

  /// Restrict results to specific keyword types.
  final List<KeywordType>? keywordTypes;

  /// Minimum monthly search volume.
  final int? minSearchVolume;

  /// Maximum SEO difficulty (0–100).
  final int? maxSeoDifficulty;

  /// Minimum opportunity score (0–100).
  final int? minOpportunityScore;

  /// Include only voice-search-friendly keywords.
  final bool? voiceSearchOnly;

  /// Include only AEO-friendly keywords.
  final bool? aeoOnly;

  /// Language code, e.g. "en", "es", "fr".
  final String language;

  const KeywordFilter({
    this.businessSegment,
    this.region,
    this.category,
    this.intents,
    this.keywordTypes,
    this.minSearchVolume,
    this.maxSeoDifficulty,
    this.minOpportunityScore,
    this.voiceSearchOnly,
    this.aeoOnly,
    this.language = 'en',
  });

  KeywordFilter copyWith({
    String? businessSegment,
    String? region,
    String? category,
    List<SearchIntent>? intents,
    List<KeywordType>? keywordTypes,
    int? minSearchVolume,
    int? maxSeoDifficulty,
    int? minOpportunityScore,
    bool? voiceSearchOnly,
    bool? aeoOnly,
    String? language,
  }) =>
      KeywordFilter(
        businessSegment: businessSegment ?? this.businessSegment,
        region: region ?? this.region,
        category: category ?? this.category,
        intents: intents ?? this.intents,
        keywordTypes: keywordTypes ?? this.keywordTypes,
        minSearchVolume: minSearchVolume ?? this.minSearchVolume,
        maxSeoDifficulty: maxSeoDifficulty ?? this.maxSeoDifficulty,
        minOpportunityScore: minOpportunityScore ?? this.minOpportunityScore,
        voiceSearchOnly: voiceSearchOnly ?? this.voiceSearchOnly,
        aeoOnly: aeoOnly ?? this.aeoOnly,
        language: language ?? this.language,
      );

  Map<String, dynamic> toJson() => {
        if (businessSegment != null) 'businessSegment': businessSegment,
        if (region != null) 'region': region,
        if (category != null) 'category': category,
        if (intents != null) 'intents': intents!.map((e) => e.name).toList(),
        if (keywordTypes != null)
          'keywordTypes': keywordTypes!.map((e) => e.name).toList(),
        if (minSearchVolume != null) 'minSearchVolume': minSearchVolume,
        if (maxSeoDifficulty != null) 'maxSeoDifficulty': maxSeoDifficulty,
        if (minOpportunityScore != null)
          'minOpportunityScore': minOpportunityScore,
        if (voiceSearchOnly != null) 'voiceSearchOnly': voiceSearchOnly,
        if (aeoOnly != null) 'aeoOnly': aeoOnly,
        'language': language,
      };
}

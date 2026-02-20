import 'search_intent.dart';
import 'keyword_type.dart';
import 'keyword_metrics.dart';
import 'seo_hint.dart';

/// Core keyword model holding the phrase and all its analysis data.
class KeywordModel {
  final String id;

  /// The keyword phrase itself.
  final String phrase;

  /// Classified search intent.
  final SearchIntent intent;

  /// Short / medium / long tail classification.
  final KeywordType keywordType;

  /// SEO / SEM metrics for this keyword.
  final KeywordMetrics metrics;

  /// Optimisation hints.
  final List<SeoHint> hints;

  /// Related or semantically similar keyword phrases.
  final List<String> relatedPhrases;

  /// Question-form variants for AEO / voice search.
  final List<String> questionVariants;

  /// Business segment tag.
  final String? businessSegment;

  /// Geographic region tag.
  final String? region;

  /// Category tag.
  final String? category;

  /// Language code.
  final String language;

  /// When this keyword was generated/analysed.
  final DateTime generatedAt;

  const KeywordModel({
    required this.id,
    required this.phrase,
    required this.intent,
    required this.keywordType,
    required this.metrics,
    this.hints = const [],
    this.relatedPhrases = const [],
    this.questionVariants = const [],
    this.businessSegment,
    this.region,
    this.category,
    this.language = 'en',
    required this.generatedAt,
  });

  /// Number of words in the phrase.
  int get wordCount => phrase.trim().split(RegExp(r'\s+')).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'phrase': phrase,
        'intent': intent.name,
        'keywordType': keywordType.name,
        'metrics': metrics.toJson(),
        'hints': hints.map((h) => h.toJson()).toList(),
        'relatedPhrases': relatedPhrases,
        'questionVariants': questionVariants,
        if (businessSegment != null) 'businessSegment': businessSegment,
        if (region != null) 'region': region,
        if (category != null) 'category': category,
        'language': language,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory KeywordModel.fromJson(Map<String, dynamic> json) => KeywordModel(
        id: json['id'] as String,
        phrase: json['phrase'] as String,
        intent: SearchIntent.values
            .firstWhere((e) => e.name == json['intent']),
        keywordType: KeywordType.values
            .firstWhere((e) => e.name == json['keywordType']),
        metrics: KeywordMetrics.fromJson(
            json['metrics'] as Map<String, dynamic>),
        relatedPhrases: List<String>.from(json['relatedPhrases'] ?? []),
        questionVariants: List<String>.from(json['questionVariants'] ?? []),
        businessSegment: json['businessSegment'] as String?,
        region: json['region'] as String?,
        category: json['category'] as String?,
        language: json['language'] as String? ?? 'en',
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );

  @override
  String toString() => 'KeywordModel("$phrase", $intent, $keywordType)';
}

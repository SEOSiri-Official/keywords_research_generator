import 'dart:async';
import 'package:uuid/uuid.dart';

import '../models/keyword_model.dart';
import '../models/keyword_filter.dart';
import '../models/keyword_list_result.dart';
import '../models/keyword_type.dart';
import 'free_apis/google_autocomplete_service.dart';
import 'free_apis/datamuse_service.dart';
import 'free_apis/google_trends_service.dart';
import 'free_apis/wikipedia_service.dart';
import 'pipeline/real_metrics_service.dart';
import 'pipeline/keyword_cluster_builder.dart';
import 'intent_analyzer_service.dart';
import 'seo_analyzer_service.dart';
import 'voice_search_service.dart';
import 'sem_optimizer_service.dart';

/// The upgraded keyword generation engine — powered entirely by free APIs.
///
/// Pipeline per keyword session:
/// 1. Google Autocomplete → 500–1,000 real phrase suggestions
/// 2. Datamuse → semantic/LSI keyword expansion
/// 3. Wikipedia → entity relationships and topic clusters
/// 4. Google Trends → real trend direction per phrase
/// 5. RealMetricsService → derives volume/difficulty from API signals
/// 6. IntentAnalyzerService → classifies each phrase by search intent
/// 7. SeoAnalyzerService + SemOptimizerService → actionable hints
/// 8. KeywordClusterBuilder → groups into semantic topic clusters
///
/// Example:
/// ```dart
/// final service = KeywordGeneratorService();
/// final result = await service.generate(
///   seedKeyword: 'flutter plugin',
///   filter: KeywordFilter(region: 'US', businessSegment: 'SaaS'),
///   onProgress: (pct, msg) => print('$pct%: $msg'),
/// );
/// print('Generated ${result.totalKeywords} real keywords');
/// ```
class KeywordGeneratorService {
  final _uuid = const Uuid();

  // ─── Free API services ────────────────────────────────────────────────────
  late final GoogleAutocompleteService _autocomplete;
  late final DatamuseService _datamuse;
  late final GoogleTrendsService _trends;
  late final WikipediaService _wikipedia;
  late final RealMetricsService _metricsService;

  // ─── Processing services ──────────────────────────────────────────────────
  final _intentAnalyzer = IntentAnalyzerService();
  final _seoAnalyzer = SeoAnalyzerService();
  final _voiceService = VoiceSearchService();
  final _semOptimizer = SemOptimizerService();
  final _clusterBuilder = KeywordClusterBuilder();

  KeywordGeneratorService() {
    _autocomplete = GoogleAutocompleteService();
    _datamuse = DatamuseService();
    _trends = GoogleTrendsService();
    _wikipedia = WikipediaService();
    _metricsService = RealMetricsService(
      trends: _trends,
      datamuse: _datamuse,
    );
  }

  // ─── Main Entry Point ─────────────────────────────────────────────────────

  /// Generates a complete keyword research session for [seedKeyword].
  ///
  /// [onProgress] receives (0–100, statusMessage) during generation.
  /// [maxKeywords] caps the output list size.
  /// [fetchTrends] — set false to skip Trends API (faster, offline-friendly).
  Future<KeywordListResult> generate({
    required String seedKeyword,
    KeywordFilter filter = const KeywordFilter(),
    int maxKeywords = 100,
    bool fetchTrends = true,
    bool fetchWikipedia = true,
    bool fetchDatumuse = true,
    void Function(int progress, String message)? onProgress,
  }) async {
    final sessionId = _uuid.v4();
    final allPhrases = <String>{};

    // ── Step 1: Google Autocomplete expansion ─────────────────────────────
    onProgress?.call(5, 'Fetching Google Autocomplete suggestions…');

    final autocompletePhrases = await _autocomplete.expand(
      seedKeyword,
      language: filter.language,
      country: filter.region?.toLowerCase() ?? 'us',
      includeAlphabetical: true,
      includeQuestions: true,
      includePrepositions: true,
      includeQualifiers: true,
      includeYouTube: true,
    );
    allPhrases.addAll(autocompletePhrases);

    onProgress?.call(25, 'Got ${allPhrases.length} phrases from Autocomplete…');

    // ── Step 2: Datamuse semantic expansion ───────────────────────────────
    if (fetchDatumuse) {
      onProgress?.call(30, 'Expanding semantic keywords via Datamuse…');
      final lsiPhrases =
          await _datamuse.expandToLsiKeywords(seedKeyword);
      allPhrases.addAll(lsiPhrases);

      final topicVocab = await _datamuse.topicVocabulary(seedKeyword);
      for (final word in topicVocab) {
        allPhrases.add('$word $seedKeyword');
        allPhrases.add('$seedKeyword $word');
      }

      onProgress?.call(40, 'Semantic expansion complete — ${allPhrases.length} unique phrases');
    }

    // ── Step 3: Wikipedia entity expansion ────────────────────────────────
    if (fetchWikipedia) {
      onProgress?.call(45, 'Fetching Wikipedia entity clusters…');
      final wikiEntity = await _wikipedia.expandEntity(seedKeyword);
      allPhrases.addAll(wikiEntity.toKeywordPhrases());

      // Category-based expansion.
      for (final cat in wikiEntity.semanticCategories.take(5)) {
        allPhrases.add('$seedKeyword $cat');
        allPhrases.add('$cat $seedKeyword');
      }

      onProgress?.call(50, 'Wikipedia expansion complete');
    }

    // ── Step 4: Region / segment / category modifiers ─────────────────────
    _addContextualPhrases(allPhrases, seedKeyword, filter);

    // ── Step 5: Clean + deduplicate ───────────────────────────────────────
    final cleanPhrases = _clean(allPhrases, seedKeyword);

    onProgress?.call(55, 'Building keyword models…');

    // ── Step 6: Fetch trend for seed (used for all derived phrases) ───────
    TrendResult? seedTrend;
    if (fetchTrends) {
      onProgress?.call(58, 'Fetching Google Trends data…');
      seedTrend = await _trends.getTrend(
        seedKeyword,
        geo: filter.region ?? '',
      );
      onProgress?.call(63, 'Trend: ${seedTrend.directionLabel}');
    }

    // ── Step 7: Build keyword models ──────────────────────────────────────
    final keywords = <KeywordModel>[];
    final total = cleanPhrases.take(maxKeywords).length;
    var processed = 0;

    for (final phrase in cleanPhrases.take(maxKeywords)) {
      final kw = await _buildKeyword(
        phrase: phrase,
        filter: filter,
        seedTrend: seedTrend,
        autocompleteRank: autocompletePhrases.indexOf(phrase),
        totalSuggestions: autocompletePhrases.length,
      );
      keywords.add(kw);
      processed++;

      if (processed % 10 == 0) {
        final pct = 63 + ((processed / total) * 30).round();
        onProgress?.call(pct, 'Built $processed / $total keyword models…');
      }
    }

    // ── Step 8: Apply filters ─────────────────────────────────────────────
    final filtered = _applyFilter(keywords, filter);

    // ── Step 9: Build clusters ────────────────────────────────────────────
    onProgress?.call(95, 'Building semantic clusters…');
    final clusters = _clusterBuilder.buildClusters(filtered);
    final clusterSummaries = _clusterBuilder.summarize(clusters);

    onProgress?.call(100, 'Complete — ${filtered.length} keywords generated');

    return KeywordListResult(
      sessionId: sessionId,
      seedKeyword: seedKeyword,
      keywords: filtered,
      filter: filter,
      generatedAt: DateTime.now(),
      clusterSummaries: clusterSummaries,
      trendDirection: seedTrend?.direction ?? 0,
      trendInterestScore: seedTrend?.interestScore ?? 50,
      risingRelatedQueries: seedTrend?.risingRelated ?? [],
    );
  }

  // ─── Contextual Phrase Builder ────────────────────────────────────────────

  void _addContextualPhrases(
    Set<String> phrases,
    String seed,
    KeywordFilter filter,
  ) {
    final s = seed.toLowerCase();

    // Region-specific
    if (filter.region != null) {
      final r = filter.region!.toLowerCase();
      phrases
        ..add('$s in $r')
        ..add('best $s in $r')
        ..add('$s near $r')
        ..add('$r $s services')
        ..add('top $s $r');
    }

    // Segment-specific
    if (filter.businessSegment != null) {
      final seg = filter.businessSegment!.toLowerCase();
      phrases
        ..add('$s for $seg')
        ..add('$seg $s solution')
        ..add('$s $seg strategy')
        ..add('best $s for $seg business')
        ..add('$s in $seg industry');
    }

    // Category-specific
    if (filter.category != null) {
      final cat = filter.category!.toLowerCase();
      phrases
        ..add('$s for $cat')
        ..add('$cat $s')
        ..add('best $cat $s')
        ..add('$s $cat tools');
    }

    // Year modifiers (always relevant for freshness)
    phrases
      ..add('$s 2024')
      ..add('$s 2025')
      ..add('$s guide 2025')
      ..add('best $s 2025');
  }

  // ─── Keyword Model Builder ────────────────────────────────────────────────

  Future<KeywordModel> _buildKeyword({
    required String phrase,
    required KeywordFilter filter,
    TrendResult? seedTrend,
    int autocompleteRank = 20,
    int totalSuggestions = 100,
  }) async {
    final wordCount = phrase.trim().split(RegExp(r'\s+')).length;
    final keywordType = KeywordTypeExtension.fromWordCount(wordCount);
    final intent = _intentAnalyzer.classify(phrase);

    // Compute real metrics.
    final metrics = await _metricsService.compute(
      phrase: phrase,
      intent: intent,
      keywordType: keywordType,
      autocompleteRank: autocompleteRank,
      totalSuggestions: totalSuggestions,
      trendResult: seedTrend,
      geo: filter.region ?? '',
    );

    // Build temporary keyword for hint generation.
    final tempKw = KeywordModel(
      id: 'tmp',
      phrase: phrase,
      intent: intent,
      keywordType: keywordType,
      metrics: metrics,
      region: filter.region,
      businessSegment: filter.businessSegment,
      category: filter.category,
      language: filter.language,
      generatedAt: DateTime.now(),
    );

    final seoHints = _seoAnalyzer.analyzeKeyword(tempKw);
    final semHints = _semOptimizer.generateSemHints(tempKw);
    final questionVariants = _voiceService.generateQuestionVariants(phrase);

    return KeywordModel(
      id: _uuid.v4(),
      phrase: phrase,
      intent: intent,
      keywordType: keywordType,
      metrics: metrics,
      hints: [...seoHints, ...semHints],
      relatedPhrases: _generateRelated(phrase),
      questionVariants: questionVariants,
      region: filter.region,
      businessSegment: filter.businessSegment,
      category: filter.category,
      language: filter.language,
      generatedAt: DateTime.now(),
    );
  }

  List<String> _generateRelated(String phrase) {
    final words = phrase.split(' ');
    if (words.isEmpty) return [];
    return [
      '${words.first} alternatives',
      '${words.first} examples',
      '$phrase tutorial',
      'best $phrase',
    ];
  }

  // ─── Cleaning ─────────────────────────────────────────────────────────────

  List<String> _clean(Set<String> phrases, String seed) {
    return phrases
        .map((p) => p.trim().toLowerCase())
        .where((p) => p.length > 2 && p.length < 120)
        .where((p) => p.split(RegExp(r'\s+')).length <= 12)
        .where((p) => !RegExp(r'[^\x00-\x7F]').hasMatch(p) == false ||
            p.contains(seed.toLowerCase().split(' ').first))
        .toSet()
        .toList()
      ..sort();
  }

  // ─── Filter ───────────────────────────────────────────────────────────────

  List<KeywordModel> _applyFilter(
    List<KeywordModel> keywords,
    KeywordFilter filter,
  ) {
    return keywords.where((kw) {
      if (filter.intents != null &&
          !filter.intents!.contains(kw.intent)) { return false; }
      if (filter.keywordTypes != null &&
          !filter.keywordTypes!.contains(kw.keywordType)) { return false; }
      if (filter.minSearchVolume != null &&
          kw.metrics.estimatedMonthlySearches < filter.minSearchVolume!) {
        return false;
      }
      if (filter.maxSeoDifficulty != null &&
          kw.metrics.seoDifficulty > filter.maxSeoDifficulty!) { return false; }
      if (filter.minOpportunityScore != null &&
          kw.metrics.opportunityScore < filter.minOpportunityScore!) {
        return false;
      }
      if (filter.voiceSearchOnly == true &&
          !kw.metrics.isVoiceSearchFriendly) { return false; }
      if (filter.aeoOnly == true && !kw.metrics.isAeoFriendly) { return false; }
      return true;
    }).toList();
  }

  void dispose() {
    _autocomplete.dispose();
    _datamuse.dispose();
    _trends.dispose();
    _wikipedia.dispose();
    _metricsService.dispose();
  }
}

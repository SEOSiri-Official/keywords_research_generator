import 'dart:convert';
import 'package:http/http.dart' as http;
import '../cache/keyword_cache_service.dart';
import '../cache/rate_limiter.dart';

/// Wikipedia & Wikidata API integration — 100% FREE.
/// No API key. Rate limit: 200 req/sec (we stay at 5).
///
/// Provides:
/// - Topic entity extraction (what concepts relate to a keyword)
/// - Semantic category tree for keyword clustering
/// - Article summary for content gap analysis
/// - Related Wikipedia titles (natural language keyword variants)
class WikipediaService {
  static const _wikiApi = 'https://en.wikipedia.org/w/api.php';

  final _cache = KeywordCacheService();
  final _client = http.Client();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns related Wikipedia page titles for [keyword].
  /// These are goldmines for natural-language keyword variants.
  Future<List<String>> relatedPageTitles(String keyword,
      {int limit = 20}) async {
    final cacheKey = 'wiki_titles_$keyword';
    final cached = await _cache.getStringList(cacheKey);
    if (cached != null) return cached;

    await ApiRateLimiters.wikipedia.throttle();

    try {
      final uri = Uri.parse(_wikiApi).replace(queryParameters: {
        'action': 'query',
        'list': 'search',
        'srsearch': keyword,
        'srlimit': '$limit',
        'format': 'json',
        'origin': '*',
      });

      final resp = await _client
          .get(uri)
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return [];

      final data = jsonDecode(resp.body);
      final results = data['query']?['search'] as List? ?? [];

      final titles = results
          .map((r) => r['title']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();

      await _cache.setStringList(cacheKey, titles);
      return titles;
    } catch (_) {
      return [];
    }
  }

  /// Returns the categories a Wikipedia page belongs to.
  /// Used to build semantic keyword clusters.
  Future<List<String>> pageCategories(String pageTitle,
      {int limit = 20}) async {
    final cacheKey = 'wiki_cats_$pageTitle';
    final cached = await _cache.getStringList(cacheKey);
    if (cached != null) return cached;

    await ApiRateLimiters.wikipedia.throttle();

    try {
      final uri = Uri.parse(_wikiApi).replace(queryParameters: {
        'action': 'query',
        'titles': pageTitle,
        'prop': 'categories',
        'cllimit': '$limit',
        'format': 'json',
        'origin': '*',
      });

      final resp = await _client
          .get(uri)
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return [];

      final data = jsonDecode(resp.body);
      final pages = data['query']?['pages'] as Map? ?? {};

      final cats = <String>[];
      for (final page in pages.values) {
        final categories = page['categories'] as List? ?? [];
        for (final cat in categories) {
          final title = (cat['title'] as String? ?? '')
              .replaceFirst('Category:', '');
          if (title.isNotEmpty && !title.toLowerCase().contains('wikipedia')) {
            cats.add(title.toLowerCase());
          }
        }
      }

      await _cache.setStringList(cacheKey, cats);
      return cats;
    } catch (_) {
      return [];
    }
  }

  /// Returns a brief summary text for content gap analysis.
  Future<String?> pageSummary(String keyword) async {
    final cacheKey = 'wiki_summary_$keyword';
    final cached = await _cache.getStringList(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached.first;

    await ApiRateLimiters.wikipedia.throttle();

    try {
      final slug =
          Uri.encodeComponent(keyword.trim().replaceAll(' ', '_'));
      final uri =
          Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$slug');

      final resp = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body);
      final summary = data['extract'] as String?;
      if (summary != null) {
        await _cache.setStringList(cacheKey, [summary]);
      }
      return summary;
    } catch (_) {
      return null;
    }
  }

  /// Full entity expansion: page titles + categories → keyword cluster.
  Future<WikiEntityResult> expandEntity(String keyword) async {
    final titles = await relatedPageTitles(keyword, limit: 10);
    final allCategories = <String>[];

    // Get categories for top 3 most-relevant pages.
    for (final title in titles.take(3)) {
      final cats = await pageCategories(title);
      allCategories.addAll(cats);
    }

    // Deduplicate categories.
    final uniqueCategories = allCategories.toSet().toList();

    return WikiEntityResult(
      keyword: keyword,
      relatedTitles: titles,
      semanticCategories: uniqueCategories,
    );
  }

  void dispose() => _client.close();
}

/// Result of a Wikipedia entity expansion.
class WikiEntityResult {
  final String keyword;

  /// Related Wikipedia article titles — natural keyword variants.
  final List<String> relatedTitles;

  /// Semantic category labels — used to build topic clusters.
  final List<String> semanticCategories;

  const WikiEntityResult({
    required this.keyword,
    required this.relatedTitles,
    required this.semanticCategories,
  });

  /// Converts related titles into SEO-friendly keyword phrases.
  List<String> toKeywordPhrases() {
    final phrases = <String>[];
    for (final title in relatedTitles) {
      phrases.add(title.toLowerCase());
      phrases.add('${title.toLowerCase()} guide');
      phrases.add('what is ${title.toLowerCase()}');
    }
    return phrases;
  }
}

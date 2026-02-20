import 'dart:convert';
import 'package:http/http.dart' as http;
import '../cache/keyword_cache_service.dart';
import '../cache/rate_limiter.dart';

/// Datamuse API integration — 100% FREE, no API key required.
/// Up to 100,000 requests/day.
///
/// Provides:
/// - Semantically related words (LSI keywords)
/// - Synonyms and near-synonyms
/// - Words triggered by a concept (topic associations)
/// - Adjectives that often precede a word
/// - Nouns that often follow a word
///
/// Docs: https://www.datamuse.com/api/
class DatamuseService {
  static const _base = 'https://api.datamuse.com';
  final _cache = KeywordCacheService();
  final _client = http.Client();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns words semantically related to [word] — core LSI keywords.
  Future<List<DatamuseWord>> relatedWords(String word, {int max = 20}) async {
    return _fetch('/words', {'ml': word, 'max': '$max'}, 'ml_$word');
  }

  /// Returns synonyms of [word].
  Future<List<DatamuseWord>> synonyms(String word, {int max = 15}) async {
    return _fetch('/words', {'rel_syn': word, 'max': '$max'}, 'syn_$word');
  }

  /// Returns words that frequently appear with [word] in the same document.
  Future<List<DatamuseWord>> cooccurring(String word, {int max = 20}) async {
    return _fetch(
        '/words', {'rel_trg': word, 'max': '$max'}, 'trg_$word');
  }

  /// Returns adjectives often used with [noun].
  Future<List<DatamuseWord>> adjectivesFor(String noun, {int max = 15}) async {
    return _fetch(
        '/words', {'rel_jjb': noun, 'max': '$max'}, 'adj_$noun');
  }

  /// Returns nouns often following [adjective].
  Future<List<DatamuseWord>> nounsAfter(String adjective,
      {int max = 15}) async {
    return _fetch(
        '/words', {'rel_jja': adjective, 'max': '$max'}, 'nn_$adjective');
  }

  /// Returns words that rhyme — useful for brand keyword brainstorming.
  Future<List<DatamuseWord>> rhymes(String word, {int max = 10}) async {
    return _fetch('/words', {'rel_rhy': word, 'max': '$max'}, 'rhy_$word');
  }

  /// Full LSI expansion: combines related, synonyms, and co-occurring terms.
  /// Returns a flat deduplicated list of keyword strings.
  Future<List<String>> expandToLsiKeywords(String phrase) async {
    final words = phrase.trim().split(RegExp(r'\s+'));
    final results = <String>{};

    for (final word in words) {
      if (word.length < 3) continue;

      final related = await relatedWords(word, max: 15);
      final synonyms_ = await synonyms(word, max: 10);
      final cooc = await cooccurring(word, max: 10);

      for (final w in [...related, ...synonyms_, ...cooc]) {
        // Only single words that score reasonably well.
        if (w.score > 500 && !w.word.contains(' ')) {
          results.add(w.word);
          // Build two-word LSI phrases with the seed.
          results.add('${w.word} $phrase');
          results.add('$phrase ${w.word}');
        }
      }
    }

    // Remove the original seed words themselves.
    for (final w in words) {
      results.remove(w);
    }

    return results.toList();
  }

  /// Returns topic-associated vocabulary for a multi-word phrase.
  /// Useful for building semantic cluster content around a keyword.
  Future<List<String>> topicVocabulary(String phrase) async {
    final cacheKey = 'topic_$phrase';
    final cached = await _cache.getStringList(cacheKey);
    if (cached != null) return cached;

    await ApiRateLimiters.datamuse.throttle();

    try {
      final uri = Uri.parse('$_base/words').replace(queryParameters: {
        'topics': phrase.replaceAll(' ', ','),
        'max': '30',
      });

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List;
      final words = data
          .map((e) => DatamuseWord.fromJson(e as Map<String, dynamic>))
          .where((w) => w.score > 200)
          .map((w) => w.word)
          .toList();

      await _cache.setStringList(cacheKey, words);
      return words;
    } catch (_) {
      return [];
    }
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<List<DatamuseWord>> _fetch(
    String path,
    Map<String, String> params,
    String cacheKey,
  ) async {
    final strCache = await _cache.getStringList('dm_$cacheKey');
    if (strCache != null) {
      return strCache
          .map((s) {
            final parts = s.split('::');
            return DatamuseWord(
                word: parts[0],
                score: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
          })
          .toList();
    }

    await ApiRateLimiters.datamuse.throttle();

    try {
      final uri =
          Uri.parse('$_base$path').replace(queryParameters: params);
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List;
      final words = data
          .map((e) => DatamuseWord.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cache as serialized strings.
      await _cache.setStringList(
        'dm_$cacheKey',
        words.map((w) => '${w.word}::${w.score}').toList(),
      );

      return words;
    } catch (_) {
      return [];
    }
  }

  void dispose() => _client.close();
}

/// A word result from Datamuse with relevance score.
class DatamuseWord {
  final String word;
  final int score;
  final List<String> tags;

  const DatamuseWord({
    required this.word,
    required this.score,
    this.tags = const [],
  });

  factory DatamuseWord.fromJson(Map<String, dynamic> json) => DatamuseWord(
        word: json['word'] as String,
        score: json['score'] as int? ?? 0,
        tags: List<String>.from(json['tags'] ?? []),
      );

  @override
  String toString() => '$word ($score)';
}

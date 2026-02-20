import 'dart:convert';
import 'package:http/http.dart' as http;
import '../cache/keyword_cache_service.dart';
import '../cache/rate_limiter.dart';

/// Fetches real keyword suggestions from Google Autocomplete.
///
/// Completely FREE — no API key required.
/// Expands one seed into 500–1,000 real phrases via:
///   - Alphabetical append: "flutter a", "flutter b" ... "flutter z"
///   - Question prefixes: "how to flutter", "what is flutter" ...
///   - Preposition expansion: "flutter for", "flutter with" ...
///   - Platform variants: YouTube, Amazon autocomplete
class GoogleAutocompleteService {
  static const _baseUrl =
      'https://suggestqueries.google.com/complete/search';
  static const _ytBaseUrl =
      'https://suggestqueries-clients6.youtube.com/complete/search';

  final _cache = KeywordCacheService();
  final _client = http.Client();

  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz';

  static const _questionPrefixes = [
    'what is', 'what are', 'how to', 'how do i', 'how can i',
    'why is', 'why does', 'when to', 'where to', 'which is',
    'who can', 'can i', 'should i', 'is it', 'what does',
  ];

  static const _prepositions = [
    'for', 'with', 'without', 'vs', 'versus', 'like',
    'instead of', 'better than', 'to', 'in', 'using',
  ];

  static const _qualifiers = [
    'best', 'free', 'top', 'cheap', 'easy', 'fast',
    'professional', '2024', '2025', 'tutorial', 'guide',
    'examples', 'alternatives', 'review',
  ];

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Fetches comprehensive Google suggestions for [seed].
  /// Returns deduplicated list of real keyword phrases.
  Future<List<String>> expand(
    String seed, {
    String language = 'en',
    String country = 'us',
    bool includeYouTube = true,
    bool includeAlphabetical = true,
    bool includeQuestions = true,
    bool includePrepositions = true,
    bool includeQualifiers = true,
  }) async {
    final results = <String>{};
    final clean = seed.trim().toLowerCase();

    // Base suggestions.
    final base = await _fetchSuggestions(clean, language, country);
    results.addAll(base);

    // Alphabetical expansion.
    if (includeAlphabetical) {
      for (final letter in _alphabet.split('')) {
        final suggestions =
            await _cachedFetch('$clean $letter', language, country);
        results.addAll(suggestions);
      }
    }

    // Question prefix expansion.
    if (includeQuestions) {
      for (final prefix in _questionPrefixes) {
        final suggestions =
            await _cachedFetch('$prefix $clean', language, country);
        results.addAll(suggestions);
      }
    }

    // Preposition expansion.
    if (includePrepositions) {
      for (final prep in _prepositions) {
        final suggestions =
            await _cachedFetch('$clean $prep', language, country);
        results.addAll(suggestions);
      }
    }

    // Qualifier expansion.
    if (includeQualifiers) {
      for (final q in _qualifiers) {
        final suggestions =
            await _cachedFetch('$q $clean', language, country);
        results.addAll(suggestions);
      }
    }

    // YouTube suggestions (video search intent).
    if (includeYouTube) {
      final ytSuggestions = await _fetchYouTubeSuggestions(clean);
      results.addAll(ytSuggestions);
    }

    // Remove the seed itself and empty strings.
    results.remove(clean);
    results.remove('');

    return results.toList()
      ..sort((a, b) => a.compareTo(b));
  }

  /// Quick fetch — just base suggestions, no expansion.
  Future<List<String>> quickSuggest(
    String query, {
    String language = 'en',
    String country = 'us',
  }) async {
    return _fetchSuggestions(query, language, country);
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  Future<List<String>> _cachedFetch(
      String query, String lang, String country) async {
    final cacheKey = 'autocomplete_${lang}_${country}_$query';
    final cached = await _cache.getStringList(cacheKey);
    if (cached != null) return cached;

    await ApiRateLimiters.autocomplete.throttle();
    final results = await _fetchSuggestions(query, lang, country);
    await _cache.setStringList(cacheKey, results);
    return results;
  }

  Future<List<String>> _fetchSuggestions(
      String query, String lang, String country) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query,
        'client': 'firefox',
        'hl': lang,
        'gl': country,
      });

      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data is! List || data.length < 2) return [];

      final suggestions = data[1];
      if (suggestions is! List) return [];

      return suggestions
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _fetchYouTubeSuggestions(String query) async {
    try {
      final uri = Uri.parse(_ytBaseUrl).replace(queryParameters: {
        'q': query,
        'client': 'youtube',
        'ds': 'yt',
      });

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return [];

      // YouTube returns JSONP: window.google.ac.h([...])
      final body = response.body;
      final start = body.indexOf('[');
      final end = body.lastIndexOf(']');
      if (start == -1 || end == -1) return [];

      final data = jsonDecode(body.substring(start, end + 1));
      if (data is! List || data.length < 2) return [];

      final suggestions = data[1];
      if (suggestions is! List) return [];

      return suggestions
          .map<String>((item) {
            if (item is List && item.isNotEmpty) return item[0].toString();
            if (item is String) return item;
            return '';
          })
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  void dispose() => _client.close();
}

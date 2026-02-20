import 'dart:convert';
import 'package:http/http.dart' as http;
import '../cache/keyword_cache_service.dart';
import '../cache/rate_limiter.dart';

/// Google Trends data via the unofficial explore endpoint.
///
/// FREE — no API key. Throttled conservatively to avoid blocks.
/// Returns trend direction, regional interest, and related queries.
class GoogleTrendsService {
  // Unofficial endpoint used by the trends.google.com UI.
  static const _exploreBase = 'https://trends.google.com/trends/api/explore';
  static const _relatedBase =
      'https://trends.google.com/trends/api/widgetdata/relatedsearches';
  static const _interestBase =
      'https://trends.google.com/trends/api/widgetdata/multiline';

  final _cache = KeywordCacheService();
  final _client = http.Client();

  /// Returns a [TrendResult] for [keyword].
  Future<TrendResult> getTrend(
    String keyword, {
    String geo = '',         // '' = global, 'US', 'GB', 'BD', etc.
    String timeframe = 'today 12-m',
    String category = '0',  // 0 = all categories
  }) async {
    final cacheKey = 'trend_${geo}_${keyword.toLowerCase()}';
    final cached = await _cache.getStringList(cacheKey);
    if (cached != null && cached.length >= 3) {
      return TrendResult(
        keyword: keyword,
        direction: int.tryParse(cached[0]) ?? 0,
        interestScore: int.tryParse(cached[1]) ?? 50,
        risingRelated: cached.sublist(2),
      );
    }

    await ApiRateLimiters.trends.throttle();

    try {
      // Step 1: get widget tokens.
      final exploreUri = Uri.parse(_exploreBase).replace(queryParameters: {
        'hl': 'en-US',
        'tz': '-330',
        'req': jsonEncode({
          'comparisonItem': [
            {'keyword': keyword, 'geo': geo, 'time': timeframe}
          ],
          'category': int.parse(category),
          'property': '',
        }),
      });

      final exploreResp = await _client
          .get(exploreUri,
              headers: {'User-Agent': 'Mozilla/5.0', 'Accept': '*/*'})
          .timeout(const Duration(seconds: 8));

      if (exploreResp.statusCode != 200) return TrendResult.neutral(keyword);

      // Strip XSSI prefix ")]}',\n"
      final raw = exploreResp.body.replaceFirst(RegExp(r"^\)]\}',[^\n]*\n"), '');
      final explore = jsonDecode(raw);

      final widgets = explore['widgets'] as List? ?? [];
      final timeWidget = widgets.firstWhere(
          (w) => w['id'] == 'TIMESERIES',
          orElse: () => null);
      final relatedWidget = widgets.firstWhere(
          (w) => w['id'] == 'RELATED_SEARCHES',
          orElse: () => null);

      int interestScore = 50;
      int direction = 0;
      List<String> risingRelated = [];

      // Step 2: get interest over time.
      if (timeWidget != null) {
        final token = timeWidget['token'] as String?;
        final req = timeWidget['request'];
        if (token != null && req != null) {
          final interestUri =
              Uri.parse(_interestBase).replace(queryParameters: {
            'hl': 'en-US',
            'tz': '-330',
            'req': jsonEncode(req),
            'token': token,
          });

          final interestResp = await _client
              .get(interestUri, headers: {'User-Agent': 'Mozilla/5.0'})
              .timeout(const Duration(seconds: 8));

          if (interestResp.statusCode == 200) {
            final iRaw = interestResp.body
                .replaceFirst(RegExp(r"^\)]\}',[^\n]*\n"), '');
            final iData = jsonDecode(iRaw);
            final timeline =
                iData?['default']?['timelineData'] as List? ?? [];

            if (timeline.isNotEmpty) {
              final values = timeline
                  .map((t) =>
                      (t['value'] as List?)?.first as int? ?? 0)
                  .toList();

              interestScore = values.isNotEmpty
                  ? (values.reduce((a, b) => a + b) / values.length).round()
                  : 50;

              // Direction = compare last 4 weeks vs. previous 4 weeks.
              if (values.length >= 8) {
                final recent = values
                        .sublist(values.length - 4)
                        .reduce((a, b) => a + b) /
                    4;
                final prior = values
                        .sublist(values.length - 8, values.length - 4)
                        .reduce((a, b) => a + b) /
                    4;
                if (recent > prior * 1.15) {
                  direction = 1; // rising
                } else if (recent < prior * 0.85) {
                  direction = -1; // declining
                }
              }
            }
          }
        }
      }

      // Step 3: get related rising searches.
      if (relatedWidget != null) {
        final token = relatedWidget['token'] as String?;
        final req = relatedWidget['request'];
        if (token != null && req != null) {
          final relUri =
              Uri.parse(_relatedBase).replace(queryParameters: {
            'hl': 'en-US',
            'tz': '-330',
            'req': jsonEncode(req),
            'token': token,
          });

          final relResp = await _client
              .get(relUri, headers: {'User-Agent': 'Mozilla/5.0'})
              .timeout(const Duration(seconds: 8));

          if (relResp.statusCode == 200) {
            final rRaw = relResp.body
                .replaceFirst(RegExp(r"^\)]\}',[^\n]*\n"), '');
            final rData = jsonDecode(rRaw);
            final rankedList = rData?['default']?['rankedList'] as List? ?? [];

            for (final ranked in rankedList) {
              final items =
                  ranked['rankedKeyword'] as List? ?? [];
              risingRelated.addAll(items
                  .where((i) => i['formattedValue'] == 'Breakout' ||
                      (i['value'] as int? ?? 0) > 50)
                  .map((i) => i['query']?.toString() ?? '')
                  .where((q) => q.isNotEmpty));
            }
          }
        }
      }

      final result = TrendResult(
        keyword: keyword,
        direction: direction,
        interestScore: interestScore,
        risingRelated: risingRelated,
      );

      // Cache result.
      await _cache.setStringList(cacheKey, [
        '$direction',
        '$interestScore',
        ...risingRelated,
      ]);

      return result;
    } catch (_) {
      return TrendResult.neutral(keyword);
    }
  }

  void dispose() => _client.close();
}

/// Trend data for a single keyword.
class TrendResult {
  final String keyword;

  /// 1 = rising, 0 = stable, -1 = declining.
  final int direction;

  /// 0–100 current interest score.
  final int interestScore;

  /// Related searches that are "Breakout" (rising fast).
  final List<String> risingRelated;

  const TrendResult({
    required this.keyword,
    required this.direction,
    required this.interestScore,
    this.risingRelated = const [],
  });

  factory TrendResult.neutral(String keyword) => TrendResult(
        keyword: keyword,
        direction: 0,
        interestScore: 50,
      );

  String get directionLabel => switch (direction) {
        1 => '📈 Rising',
        -1 => '📉 Declining',
        _ => '➡️ Stable',
      };
}

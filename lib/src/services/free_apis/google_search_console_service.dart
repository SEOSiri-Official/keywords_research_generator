import 'dart:convert';
import 'package:http/http.dart' as http;
import '../cache/keyword_cache_service.dart';
import '../cache/rate_limiter.dart';

/// Google Search Console API integration — 100% FREE.
///
/// Pass your OAuth access token directly — obtain it via your preferred
/// OAuth flow (google_sign_in, oauth2, or any Google auth library).
///
/// Scopes required: https://www.googleapis.com/auth/webmasters.readonly
class GoogleSearchConsoleService {
  static const _baseUrl =
      'https://searchconsole.googleapis.com/webmasters/v3';

  final _cache = KeywordCacheService();
  final _client = http.Client();

  String? _accessToken;
  String? _userEmail;

  // ── Auth ────────────────────────────────────────────────────

  /// Set access token obtained from your OAuth flow.
  void setAccessToken(String token, {String? email}) {
    _accessToken = token;
    _userEmail = email;
  }

  /// Clear credentials.
  void signOut() {
    _accessToken = null;
    _userEmail = null;
  }

  bool get isSignedIn => _accessToken != null && _accessToken!.isNotEmpty;
  String? get userEmail => _userEmail;

  // ── Properties ──────────────────────────────────────────────

  Future<List<GscProperty>> listProperties() async {
    if (!isSignedIn) return [];
    try {
      final resp = await _get('/sites');
      if (resp == null) return [];
      final sites = resp['siteEntry'] as List? ?? [];
      return sites
          .map((s) => GscProperty.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Keyword Data ────────────────────────────────────────────

  Future<List<GscKeywordRow>> getKeywords({
    required String siteUrl,
    String? startDate,
    String? endDate,
    int rowLimit = 1000,
    List<String> dimensions = const ['query'],
    String? country,
  }) async {
    if (!isSignedIn) return [];

    final now = DateTime.now();
    final start = startDate ??
        DateTime(now.year, now.month - 3, now.day)
            .toIso8601String()
            .substring(0, 10);
    final end = endDate ?? now.toIso8601String().substring(0, 10);

    final cacheKey = 'gsc_${siteUrl}_${start}_$end';
    final cached = await _cache.getStringList(cacheKey);
    if (cached != null) {
      return cached
          .map((s) => GscKeywordRow.fromCsv(s))
          .whereType<GscKeywordRow>()
          .toList();
    }

    await ApiRateLimiters.searchConsole.throttle();

    try {
      final body = <String, dynamic>{
        'startDate': start,
        'endDate': end,
        'dimensions': dimensions,
        'rowLimit': rowLimit,
      };

      if (country != null) {
        body['dimensionFilterGroups'] = [
          {
            'filters': [
              {
                'dimension': 'country',
                'expression': country.toUpperCase(),
                'operator': 'equals',
              }
            ]
          }
        ];
      }

      final encodedSite = Uri.encodeComponent(siteUrl);
      final resp = await _post(
        '/sites/$encodedSite/searchAnalytics/query',
        body,
      );

      if (resp == null) return [];

      final rows = resp['rows'] as List? ?? [];
      final keywords = rows.map((r) {
        final keys = r['keys'] as List? ?? [];
        return GscKeywordRow(
          query: keys.isNotEmpty ? keys[0].toString() : '',
          clicks: (r['clicks'] as num?)?.toInt() ?? 0,
          impressions: (r['impressions'] as num?)?.toInt() ?? 0,
          ctr: (r['ctr'] as num?)?.toDouble() ?? 0.0,
          position: (r['position'] as num?)?.toDouble() ?? 0.0,
        );
      }).where((r) => r.query.isNotEmpty).toList();

      await _cache.setStringList(
          cacheKey, keywords.map((k) => k.toCsv()).toList());

      return keywords;
    } catch (_) {
      return [];
    }
  }

  Future<List<GscKeywordRow>> strikingDistanceKeywords({
    required String siteUrl,
    String? country,
    int minImpressions = 100,
  }) async {
    final all = await getKeywords(siteUrl: siteUrl, country: country);
    return all
        .where((k) =>
            k.position >= 11 &&
            k.position <= 20 &&
            k.impressions >= minImpressions)
        .toList()
      ..sort((a, b) => b.impressions.compareTo(a.impressions));
  }

  Future<List<GscKeywordRow>> topKeywords({
    required String siteUrl,
    int limit = 50,
  }) async {
    final all = await getKeywords(siteUrl: siteUrl);
    return all
        .where((k) => k.position <= 3)
        .take(limit)
        .toList()
      ..sort((a, b) => b.clicks.compareTo(a.clicks));
  }

  Future<List<GscKeywordRow>> findCannibalizationRisks({
    required String siteUrl,
  }) async {
    final withPage = await getKeywords(
      siteUrl: siteUrl,
      dimensions: ['query', 'page'],
    );
    final byQuery = <String, List<GscKeywordRow>>{};
    for (final row in withPage) {
      byQuery.putIfAbsent(row.query, () => []).add(row);
    }
    return byQuery.entries
        .where((e) => e.value.length > 1)
        .map((e) => e.value.first)
        .toList();
  }

  // ── HTTP ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final resp = await _client
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final resp = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}

// ── Models ──────────────────────────────────────────────────────

class GscProperty {
  final String siteUrl;
  final String permissionLevel;
  const GscProperty({required this.siteUrl, required this.permissionLevel});
  factory GscProperty.fromJson(Map<String, dynamic> json) => GscProperty(
        siteUrl: json['siteUrl'] as String,
        permissionLevel: json['permissionLevel'] as String? ?? 'siteOwner',
      );
}

class GscKeywordRow {
  final String query;
  final int clicks;
  final int impressions;
  final double ctr;
  final double position;
  final String? page;

  const GscKeywordRow({
    required this.query,
    required this.clicks,
    required this.impressions,
    required this.ctr,
    required this.position,
    this.page,
  });

  String get ctrPercent => '${(ctr * 100).toStringAsFixed(1)}%';
  String get positionLabel => position.toStringAsFixed(1);
  bool get isStrikingDistance => position >= 11 && position <= 20;

  String toCsv() =>
      '$query|$clicks|$impressions|$ctr|$position|${page ?? ''}';

  static GscKeywordRow? fromCsv(String csv) {
    try {
      final p = csv.split('|');
      if (p.length < 5) return null;
      return GscKeywordRow(
        query: p[0],
        clicks: int.tryParse(p[1]) ?? 0,
        impressions: int.tryParse(p[2]) ?? 0,
        ctr: double.tryParse(p[3]) ?? 0,
        position: double.tryParse(p[4]) ?? 0,
        page: p.length > 5 ? p[5] : null,
      );
    } catch (_) {
      return null;
    }
  }
}
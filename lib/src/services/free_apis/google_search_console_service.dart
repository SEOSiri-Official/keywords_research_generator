import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../cache/keyword_cache_service.dart';
import '../cache/rate_limiter.dart';

/// Google Search Console API integration — 100% FREE.
///
/// Requires the user to authenticate with their Google account.
/// Gives REAL search data (clicks, impressions, CTR, position)
/// for keywords on their own verified properties.
///
/// OAuth scopes: https://www.googleapis.com/auth/webmasters.readonly
///
/// Setup (one-time in your app):
/// 1. Create project at console.cloud.google.com (free)
/// 2. Enable "Search Console API"
/// 3. Create OAuth 2.0 credentials (Web/Android/iOS)
/// 4. Add OAuth client ID to your app
class GoogleSearchConsoleService {
  static const _baseUrl =
      'https://searchconsole.googleapis.com/webmasters/v3';

  static const _scopes = [
    'https://www.googleapis.com/auth/webmasters.readonly',
  ];

  final _googleSignIn = GoogleSignIn(scopes: _scopes);
  final _cache = KeywordCacheService();
  final _client = http.Client();

  GoogleSignInAccount? _account;
  String? _accessToken;

  // ─── Auth ──────────────────────────────────────────────────────────────────

  /// Signs in the user. Returns true if successful.
  Future<bool> signIn() async {
    try {
      _account = await _googleSignIn.signIn();
      if (_account == null) return false;

      final auth = await _account!.authentication;
      _accessToken = auth.accessToken;
      return _accessToken != null;
    } catch (_) {
      return false;
    }
  }

  /// Signs out.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
    _accessToken = null;
  }

  bool get isSignedIn => _accessToken != null;
  String? get userEmail => _account?.email;

  // ─── Properties ────────────────────────────────────────────────────────────

  /// Lists verified Search Console properties for the signed-in user.
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

  // ─── Keyword Data ──────────────────────────────────────────────────────────

  /// Returns real keyword performance data for [siteUrl].
  ///
  /// [startDate] and [endDate] in 'YYYY-MM-DD' format.
  /// Default: last 90 days.
  Future<List<GscKeywordRow>> getKeywords({
    required String siteUrl,
    String? startDate,
    String? endDate,
    int rowLimit = 1000,
    List<String> dimensions = const ['query'],
    String? country,
    String? device,
  }) async {
    if (!isSignedIn) return [];

    final now = DateTime.now();
    final start = startDate ??
        DateTime(now.year, now.month - 3, now.day)
            .toIso8601String()
            .substring(0, 10);
    final end =
        endDate ?? now.toIso8601String().substring(0, 10);

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

      // Cache.
      await _cache.setStringList(
          cacheKey, keywords.map((k) => k.toCsv()).toList());

      return keywords;
    } catch (_) {
      return [];
    }
  }

  /// Returns "striking distance" keywords — position 11–20, high impressions.
  /// These are closest to page 1 with minimal effort.
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

  /// Returns top performing keywords (position 1–3).
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

  /// Detects keyword cannibalization — multiple pages competing for same query.
  Future<List<GscKeywordRow>> findCannibalizationRisks({
    required String siteUrl,
  }) async {
    final withPage = await getKeywords(
      siteUrl: siteUrl,
      dimensions: ['query', 'page'],
    );

    // Group by query — queries appearing on 2+ pages = risk.
    final byQuery = <String, List<GscKeywordRow>>{};
    for (final row in withPage) {
      byQuery.putIfAbsent(row.query, () => []).add(row);
    }

    return byQuery.entries
        .where((e) => e.value.length > 1)
        .map((e) => e.value.first)
        .toList();
  }

  // ─── HTTP Helpers ──────────────────────────────────────────────────────────

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

      if (resp.statusCode == 401) await _refreshToken();
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

      if (resp.statusCode == 401) await _refreshToken();
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshToken() async {
    if (_account == null) return;
    final auth = await _account!.authentication;
    _accessToken = auth.accessToken;
  }

  void dispose() => _client.close();
}

// ─── Data models ──────────────────────────────────────────────────────────────

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

  /// CTR as percentage string.
  String get ctrPercent => '${(ctr * 100).toStringAsFixed(1)}%';

  /// Rounded position.
  String get positionLabel => position.toStringAsFixed(1);

  /// Is this a striking distance keyword?
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

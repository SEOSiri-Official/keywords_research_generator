import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Two-layer keyword cache:
/// - L1: in-memory HashMap (instant, cleared on app restart)
/// - L2: SharedPreferences (persisted to device, survives restarts)
///
/// Free-API results are expensive in rate-limit terms, not money.
/// Caching ensures we never hit the same query twice.
class KeywordCacheService {
  static const _prefix = 'krg_cache_';
  static const _ttlHours = 24; // cache lives 24 hours

  // L1 in-memory cache
  final Map<String, _CacheEntry> _memory = {};

  static KeywordCacheService? _instance;
  KeywordCacheService._();

  factory KeywordCacheService() {
    _instance ??= KeywordCacheService._();
    return _instance!;
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns cached value for [key], or null if missing/expired.
  Future<List<String>?> getStringList(String key) async {
    final cacheKey = _key(key);

    // L1 hit
    final mem = _memory[cacheKey];
    if (mem != null && !mem.isExpired) return mem.data;

    // L2 hit
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entry = _CacheEntry.fromJson(map);
      if (entry.isExpired) {
        await prefs.remove(cacheKey);
        return null;
      }
      _memory[cacheKey] = entry; // promote to L1
      return entry.data;
    } catch (_) {
      return null;
    }
  }

  /// Stores [data] under [key] in both L1 and L2.
  Future<void> setStringList(String key, List<String> data) async {
    final cacheKey = _key(key);
    final entry = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(const Duration(hours: _ttlHours)),
    );

    _memory[cacheKey] = entry;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(entry.toJson()));
  }

  /// Clears all cached keyword data.
  Future<void> clearAll() async {
    _memory.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Stats: number of cached entries in L1.
  int get memoryCacheSize => _memory.length;

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _key(String raw) =>
      '$_prefix${raw.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
}

class _CacheEntry {
  final List<String> data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'data': data,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
        data: List<String>.from(json['data'] as List),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

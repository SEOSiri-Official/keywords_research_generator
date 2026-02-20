import 'dart:async';
import 'dart:collection';

/// Token-bucket rate limiter to stay within free API quotas.
///
/// Each [RateLimiter] instance manages one API endpoint.
/// Usage:
/// ```dart
/// final limiter = RateLimiter(requestsPerSecond: 2);
/// await limiter.throttle();  // waits if too fast
/// ```
class RateLimiter {
  final int requestsPerSecond;
  final Queue<DateTime> _timestamps = Queue();

  RateLimiter({this.requestsPerSecond = 2});

  /// Waits if needed so we never exceed [requestsPerSecond].
  Future<void> throttle() async {
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(seconds: 1));

    // Drop timestamps outside the 1-second window.
    while (_timestamps.isNotEmpty && _timestamps.first.isBefore(windowStart)) {
      _timestamps.removeFirst();
    }

    if (_timestamps.length >= requestsPerSecond) {
      // How long until the oldest timestamp falls out of window?
      final wait = _timestamps.first
          .add(const Duration(seconds: 1))
          .difference(DateTime.now());
      if (wait.isNegative == false) {
        await Future.delayed(wait + const Duration(milliseconds: 50));
      }
    }

    _timestamps.addLast(DateTime.now());
  }
}

/// Pre-configured limiters for each free API we use.
class ApiRateLimiters {
  ApiRateLimiters._();

  /// Google Autocomplete — safe at 2 req/sec (unofficial limit).
  static final autocomplete = RateLimiter(requestsPerSecond: 2);

  /// Datamuse — documented at 100,000 req/day; ~1 req/sec is safe.
  static final datamuse = RateLimiter(requestsPerSecond: 3);

  /// Wikipedia — 200 req/sec for anonymous; we stay at 5.
  static final wikipedia = RateLimiter(requestsPerSecond: 5);

  /// Google Trends (unofficial) — aggressive throttle to avoid blocks.
  static final trends = RateLimiter(requestsPerSecond: 1);

  /// Google Search Console API — 1200 req/min quota; 10/sec safe.
  static final searchConsole = RateLimiter(requestsPerSecond: 10);
}

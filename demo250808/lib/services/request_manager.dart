import 'dart:async';
import 'dart:math';

/// Enhanced request manager with rate limiting, exponential backoff, and caching
class RequestManager {
  static final RequestManager _instance = RequestManager._internal();
  factory RequestManager() => _instance;
  RequestManager._internal();

  // Rate limiting tracking
  final Map<String, List<DateTime>> _requestHistory = {};
  final Map<String, DateTime> _nextAllowedRequest = {};
  final Map<String, int> _failureCount = {};
  
  // Caching
  final Map<String, _CacheEntry> _cache = {};
  
  static const int _maxRequestsPerMinute = 20;
  static const int _maxRequestsPer5Minutes = 60;
  static const Duration _baseCooldownPeriod = Duration(seconds: 1);
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Check if request is allowed based on rate limits
  bool isRequestAllowed(String endpoint) {
    final now = DateTime.now();
    
    // Check cooldown from previous failures
    if (_nextAllowedRequest.containsKey(endpoint)) {
      if (now.isBefore(_nextAllowedRequest[endpoint]!)) {
        return false;
      }
    }

    // Clean old request history
    _requestHistory[endpoint]?.removeWhere(
      (time) => now.difference(time).inMinutes > 5
    );

    final history = _requestHistory[endpoint] ?? [];
    
    // Check 1-minute limit
    final recentRequests = history.where(
      (time) => now.difference(time).inMinutes < 1
    ).length;
    
    if (recentRequests >= _maxRequestsPerMinute) {
      return false;
    }

    // Check 5-minute limit
    if (history.length >= _maxRequestsPer5Minutes) {
      return false;
    }

    return true;
  }

  /// Record a successful request
  void recordRequest(String endpoint) {
    final now = DateTime.now();
    _requestHistory.putIfAbsent(endpoint, () => []).add(now);
    _failureCount[endpoint] = 0; // Reset failure count on success
  }

  /// Record a failed request and calculate cooldown
  void recordFailure(String endpoint, {String? errorMessage}) {
    final now = DateTime.now();
    final currentFailures = (_failureCount[endpoint] ?? 0) + 1;
    _failureCount[endpoint] = currentFailures;

    // Exponential backoff calculation
    final backoffSeconds = min(
      _baseCooldownPeriod.inSeconds * pow(2, currentFailures - 1).toInt(),
      300 // Max 5 minutes
    );
    
    _nextAllowedRequest[endpoint] = now.add(Duration(seconds: backoffSeconds));
    
    print('Request failed for $endpoint. Failure count: $currentFailures. '
           'Next allowed: ${_nextAllowedRequest[endpoint]}');
  }

  /// Get cooldown time remaining for an endpoint
  Duration getCooldownRemaining(String endpoint) {
    if (!_nextAllowedRequest.containsKey(endpoint)) {
      return Duration.zero;
    }
    
    final now = DateTime.now();
    final nextAllowed = _nextAllowedRequest[endpoint]!;
    
    if (now.isAfter(nextAllowed)) {
      return Duration.zero;
    }
    
    return nextAllowed.difference(now);
  }

  /// Execute request with rate limiting and retry logic
  Future<T> executeRequest<T>(
    String endpoint,
    Future<T> Function() request, {
    int maxRetries = 3,
    bool useCache = false,
    Duration? cacheExpiry,
  }) async {
    // Check cache first
    if (useCache) {
      final cached = _getFromCache<T>(endpoint);
      if (cached != null) {
        return cached;
      }
    }

    // Check rate limits
    if (!isRequestAllowed(endpoint)) {
      final cooldown = getCooldownRemaining(endpoint);
      throw RequestLimitException(
        'Request rate limit exceeded for $endpoint. '
        'Try again in ${cooldown.inSeconds} seconds.'
      );
    }

    Exception? lastException;
    
    for (int attempt = 0; attempt < maxRetries + 1; attempt++) {
      try {
        // Add jitter to prevent thundering herd
        if (attempt > 0) {
          final jitter = Random().nextInt(1000);
          await Future.delayed(Duration(milliseconds: 100 + jitter));
        }

        final result = await request();
        
        // Record success and cache if enabled
        recordRequest(endpoint);
        if (useCache) {
          _addToCache(endpoint, result, cacheExpiry ?? _cacheExpiry);
        }
        
        return result;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Don't retry on certain errors
        if (_isNonRetryableError(e)) {
          recordFailure(endpoint, errorMessage: e.toString());
          throw lastException;
        }
        
        // Record failure for exponential backoff
        if (attempt == maxRetries) {
          recordFailure(endpoint, errorMessage: e.toString());
        }
        
        print('Request attempt ${attempt + 1} failed for $endpoint: $e');
      }
    }
    
    throw lastException ?? Exception('Max retries exceeded for $endpoint');
  }

  /// Check if error should not trigger retry
  bool _isNonRetryableError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('invalid-credential') ||
           errorStr.contains('user-not-found') ||
           errorStr.contains('wrong-password') ||
           errorStr.contains('invalid-email') ||
           errorStr.contains('user-disabled') ||
           errorStr.contains('email-already-in-use');
  }

  /// Get cached result
  T? _getFromCache<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T?;
  }

  /// Add result to cache
  void _addToCache<T>(String key, T data, Duration expiry) {
    _cache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(expiry),
    );
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
  }

  /// Clear rate limiting data for endpoint
  void clearRateLimit(String endpoint) {
    _requestHistory.remove(endpoint);
    _nextAllowedRequest.remove(endpoint);
    _failureCount.remove(endpoint);
  }

  /// Get current rate limit status
  Map<String, dynamic> getRateLimitStatus(String endpoint) {
    final now = DateTime.now();
    final history = _requestHistory[endpoint] ?? [];
    final recentRequests = history.where(
      (time) => now.difference(time).inMinutes < 1
    ).length;
    
    return {
      'endpoint': endpoint,
      'recentRequests': recentRequests,
      'maxPerMinute': _maxRequestsPerMinute,
      'totalRequests': history.length,
      'maxPer5Minutes': _maxRequestsPer5Minutes,
      'failureCount': _failureCount[endpoint] ?? 0,
      'cooldownRemaining': getCooldownRemaining(endpoint).inSeconds,
      'isAllowed': isRequestAllowed(endpoint),
    };
  }
}

/// Cache entry with expiry
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;
  
  _CacheEntry({required this.data, required this.expiry});
}

/// Custom exception for request limits
class RequestLimitException implements Exception {
  final String message;
  RequestLimitException(this.message);
  
  @override
  String toString() => 'RequestLimitException: $message';
}
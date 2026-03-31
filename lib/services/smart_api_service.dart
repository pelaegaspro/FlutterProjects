import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_resilience.dart';
import 'cricapi_service.dart';
import 'sportradar_service.dart';

/// Simple in-memory TTL cache entry.
class _CacheEntry<T> {
  _CacheEntry(this.value, this.expiresAt);
  final T value;
  final DateTime expiresAt;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class SmartAPIService {
  final SportradarService _primary = SportradarService();
  final CricApiService _fallback = CricApiService();

  static const Duration _matchCacheTtl = Duration(seconds: 45);

  // Per-category caches so individual lists can be refreshed independently.
  _CacheEntry<List<Match>>? _liveCache;
  _CacheEntry<List<Match>>? _upcomingCache;
  _CacheEntry<List<Match>>? _completedCache;

  /// Flat id→Match index rebuilt whenever any category cache is refreshed.
  final Map<String, Match> _matchIndex = {};

  void _indexMatches(List<Match> matches) {
    for (final m in matches) {
      if (m.id.isNotEmpty) _matchIndex[m.id] = m;
    }
  }

  Future<List<Match>> fetchLiveMatches({bool forceRefresh = false}) async {
    if (!forceRefresh && _liveCache != null && !_liveCache!.isExpired) {
      return _liveCache!.value;
    }
    final result = await _fetchWithFallback(
      primaryCall: _primary.fetchLiveMatches,
      fallbackCall: _fallback.fetchLiveMatches,
      emptyValue: const <Match>[],
      operationName: 'live matches',
    );
    _liveCache = _CacheEntry(result, DateTime.now().add(_matchCacheTtl));
    _indexMatches(result);
    return result;
  }

  Future<List<Match>> fetchUpcomingMatches({bool forceRefresh = false}) async {
    if (!forceRefresh && _upcomingCache != null && !_upcomingCache!.isExpired) {
      return _upcomingCache!.value;
    }
    final result = await _fetchWithFallback(
      primaryCall: _primary.fetchUpcomingMatches,
      fallbackCall: _fallback.fetchUpcomingMatches,
      emptyValue: const <Match>[],
      operationName: 'upcoming matches',
    );
    _upcomingCache = _CacheEntry(result, DateTime.now().add(_matchCacheTtl));
    _indexMatches(result);
    return result;
  }

  Future<List<Match>> fetchCompletedMatches({bool forceRefresh = false}) async {
    if (!forceRefresh && _completedCache != null && !_completedCache!.isExpired) {
      return _completedCache!.value;
    }
    final result = await _fetchWithFallback(
      primaryCall: _primary.fetchCompletedMatches,
      fallbackCall: _fallback.fetchCompletedMatches,
      emptyValue: const <Match>[],
      operationName: 'completed matches',
    );
    _completedCache = _CacheEntry(result, DateTime.now().add(_matchCacheTtl));
    _indexMatches(result);
    return result;
  }

  Future<List<Match>> fetchAllMatches({bool forceRefresh = false}) async {
    final live = await fetchLiveMatches(forceRefresh: forceRefresh);
    final upcoming = await fetchUpcomingMatches(forceRefresh: forceRefresh);
    final completed = await fetchCompletedMatches(forceRefresh: forceRefresh);

    final deduped = <String, Match>{};
    for (final match in [...live, ...upcoming, ...completed]) {
      if (match.id.isEmpty) continue;
      deduped[match.id] = match;
    }

    return deduped.values.toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// O(1) lookup — uses the in-memory index if already populated,
  /// otherwise seeds the index by fetching all matches once.
  Future<Match?> fetchMatchById(String matchId) async {
    if (_matchIndex.containsKey(matchId)) {
      return _matchIndex[matchId];
    }
    // Index empty (cold start) — populate it then look up.
    await fetchAllMatches();
    return _matchIndex[matchId];
  }

  Future<List<Player>> fetchMatchPlayers(String matchId) {
    return _fetchWithFallback(
      primaryCall: () => _primary.fetchMatchPlayers(matchId),
      fallbackCall: () => _fallback.fetchMatchPlayers(matchId),
      emptyValue: const <Player>[],
      operationName: 'match players for $matchId',
    );
  }

  /// Invalidates all caches and the match index (e.g. on pull-to-refresh).
  void invalidateCache() {
    _liveCache = null;
    _upcomingCache = null;
    _completedCache = null;
    _matchIndex.clear();
  }

  Future<T> _fetchWithFallback<T>({
    required Future<T> Function() primaryCall,
    required Future<T> Function() fallbackCall,
    required T emptyValue,
    required String operationName,
  }) async {
    try {
      return await ApiResilience.retry(
        primaryCall,
        onRetry: (error, attempt, delay) {
          debugPrint(
            'Retrying primary source for $operationName '
            '(attempt ${attempt + 1} after ${delay.inMilliseconds}ms): $error',
          );
        },
      );
    } catch (primaryError) {
      debugPrint('Primary source failed for $operationName, switching to backup: $primaryError');

      try {
        return await ApiResilience.retry(
          fallbackCall,
          maxAttempts: 2,
          onRetry: (error, attempt, delay) {
            debugPrint(
              'Retrying backup source for $operationName '
              '(attempt ${attempt + 1} after ${delay.inMilliseconds}ms): $error',
            );
          },
        );
      } catch (fallbackError) {
        debugPrint(
          'Backup source also failed for $operationName. '
          'Returning safe empty value: $fallbackError',
        );
        return emptyValue;
      }
    }
  }
}

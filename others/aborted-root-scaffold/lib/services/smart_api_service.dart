import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_resilience.dart';
import 'cricapi_service.dart';
import 'sportradar_service.dart';

class SmartAPIService {
  final SportradarService _primary = SportradarService();
  final CricApiService _fallback = CricApiService();

  Future<List<Match>> fetchLiveMatches() {
    return _fetchWithFallback(
      primaryCall: _primary.fetchLiveMatches,
      fallbackCall: _fallback.fetchLiveMatches,
      emptyValue: const <Match>[],
      operationName: 'live matches',
    );
  }

  Future<List<Match>> fetchUpcomingMatches() {
    return _fetchWithFallback(
      primaryCall: _primary.fetchUpcomingMatches,
      fallbackCall: _fallback.fetchUpcomingMatches,
      emptyValue: const <Match>[],
      operationName: 'upcoming matches',
    );
  }

  Future<List<Match>> fetchCompletedMatches() {
    return _fetchWithFallback(
      primaryCall: _primary.fetchCompletedMatches,
      fallbackCall: _fallback.fetchCompletedMatches,
      emptyValue: const <Match>[],
      operationName: 'completed matches',
    );
  }

  Future<List<Match>> fetchAllMatches() async {
    final live = await fetchLiveMatches();
    final upcoming = await fetchUpcomingMatches();
    final completed = await fetchCompletedMatches();

    final deduped = <String, Match>{};
    for (final match in [...live, ...upcoming, ...completed]) {
      if (match.id.isEmpty) {
        continue;
      }
      deduped[match.id] = match;
    }

    return deduped.values.toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Future<Match?> fetchMatchById(String matchId) async {
    final matches = await fetchAllMatches();
    for (final match in matches) {
      if (match.id == matchId) {
        return match;
      }
    }
    return null;
  }

  Future<List<Player>> fetchMatchPlayers(String matchId) {
    return _fetchWithFallback(
      primaryCall: () => _primary.fetchMatchPlayers(matchId),
      fallbackCall: () => _fallback.fetchMatchPlayers(matchId),
      emptyValue: const <Player>[],
      operationName: 'match players for $matchId',
    );
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

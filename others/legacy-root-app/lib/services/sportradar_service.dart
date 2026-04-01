import 'package:dio/dio.dart';

import '../core/app_config.dart';
import '../models/models.dart';

class SportradarService {
  SportradarService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.premiumFeedBase,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: {
              if (AppConfig.premiumFeedApiKey.isNotEmpty)
                'Authorization': 'Bearer ${AppConfig.premiumFeedApiKey}',
            },
          ),
        );

  final Dio _dio;

  Future<List<Match>> fetchLiveMatches() => _fetchMatches('/matches/live');

  Future<List<Match>> fetchUpcomingMatches() => _fetchMatches('/matches/upcoming');

  Future<List<Match>> fetchCompletedMatches() => _fetchMatches('/matches/completed');

  Future<List<Player>> fetchMatchPlayers(String matchId) async {
    _ensureConfigured();
    final response = await _dio.get('/matches/$matchId/players');
    final items = _extractDataList(response.data);
    return items.map(Player.fromJson).toList();
  }

  Future<List<Match>> _fetchMatches(String path) async {
    _ensureConfigured();
    final response = await _dio.get(path);
    final items = _extractDataList(response.data);
    return items.map(Match.fromJson).toList();
  }

  List<Map<String, dynamic>> _extractDataList(dynamic payload) {
    if (payload is Map && payload['data'] is List) {
      return (payload['data'] as List)
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }

    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    }

    return const [];
  }

  void _ensureConfigured() {
    if (!AppConfig.hasPremiumFeedConfig) {
      throw StateError(
        'PREMIUM_FEED_BASE_URL and PREMIUM_FEED_API_KEY are not configured.',
      );
    }
  }
}

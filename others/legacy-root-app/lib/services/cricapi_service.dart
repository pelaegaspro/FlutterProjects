import 'package:dio/dio.dart';

import '../core/app_config.dart';
import '../models/models.dart';

class CricApiService {
  CricApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.cricApiBase,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

  final Dio _dio;

  Future<List<Match>> fetchLiveMatches() async {
    final matches = await _fetchMatches();
    return matches.where((match) => match.isLive).toList();
  }

  Future<List<Match>> fetchUpcomingMatches() async {
    final matches = await _fetchMatches();
    return matches.where((match) => match.isUpcoming).toList();
  }

  Future<List<Match>> fetchCompletedMatches() async {
    final matches = await _fetchMatches();
    return matches.where((match) => match.isCompleted).toList();
  }

  Future<List<Player>> fetchMatchPlayers(String matchId) async {
    _ensureConfigured();

    for (final endpoint in ['match_squad', 'match_info']) {
      try {
        final response = await _dio.get(
          endpoint,
          queryParameters: {
            'apikey': AppConfig.cricApiKey,
            'id': matchId,
          },
        );

        final players = _extractPlayers(response.data);
        if (players.isNotEmpty) {
          return players;
        }
      } on DioException {
        continue;
      }
    }

    return const [];
  }

  Future<List<Match>> _fetchMatches() async {
    _ensureConfigured();

    final endpoints = ['cricScore', 'currentMatches'];
    final allMatches = <Match>[];

    for (final endpoint in endpoints) {
      try {
        final response = await _dio.get(
          endpoint,
          queryParameters: {
            'apikey': AppConfig.cricApiKey,
            'offset': 0,
          },
        );

        final matches = _extractMatches(response.data);
        if (matches.isNotEmpty) {
          allMatches.addAll(matches);
          break;
        }
      } on DioException {
        continue;
      }
    }

    final deduped = <String, Match>{};
    for (final match in allMatches) {
      if (match.id.isEmpty) {
        continue;
      }
      deduped[match.id] = match;
    }
    return deduped.values.toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  List<Match> _extractMatches(dynamic payload) {
    final items = _extractDataList(payload);
    return items
        .map(Match.fromCricApi)
        .where((match) => match.id.isNotEmpty && match.teamA.isNotEmpty && match.teamB.isNotEmpty)
        .toList();
  }

  List<Player> _extractPlayers(dynamic payload) {
    final root = payload is Map ? payload.cast<String, dynamic>() : <String, dynamic>{};
    final data = root['data'];

    final teams = <String, List<Map<String, dynamic>>>{};

    void collectPlayers(dynamic source, {String teamName = ''}) {
      if (source is List) {
        for (final entry in source.whereType<Map>()) {
          final map = entry.cast<String, dynamic>();
          final nestedPlayers = map['players'] ?? map['squad'];
          final nestedTeamName = map['name']?.toString() ??
              map['teamName']?.toString() ??
              map['shortname']?.toString() ??
              teamName;
          if (nestedPlayers != null) {
            collectPlayers(nestedPlayers, teamName: nestedTeamName);
          } else if (map['name'] != null &&
              (map['id'] != null ||
                  map['playerId'] != null ||
                  map['role'] != null ||
                  map['playingRole'] != null ||
                  map['speciality'] != null)) {
            final bucket = teams.putIfAbsent(teamName, () => <Map<String, dynamic>>[]);
            bucket.add(map);
          }
        }
      } else if (source is Map) {
        final map = source.cast<String, dynamic>();
        for (final key in ['teamInfo', 'teams', 'squad', 'players']) {
          if (map[key] != null) {
            collectPlayers(map[key], teamName: teamName);
          }
        }
      }
    }

    collectPlayers(data, teamName: '');
    if (teams.isEmpty) {
      collectPlayers(root, teamName: '');
    }

    final players = <Player>[];
    teams.forEach((teamName, entries) {
      for (final player in entries) {
        players.add(
          Player.fromCricApi(
            player,
            team: teamName.isEmpty ? 'TBD' : teamName,
          ),
        );
      }
    });

    final deduped = <String, Player>{};
    for (final player in players) {
      if (player.id.isEmpty) {
        continue;
      }
      deduped[player.id] = player;
    }
    return deduped.values.toList();
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
    if (!AppConfig.hasCricApiConfig) {
      throw StateError('CRICAPI_API_KEY is not configured.');
    }
  }
}

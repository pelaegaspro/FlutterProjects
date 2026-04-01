import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/models.dart';

class TeamGeneratorService {
  Future<List<GeneratedTeam>> generateTeams({
    required List<FantasyPlayer> players,
    required int requestedCount,
  }) async {
    final rawTeams = await compute(
      _generateTeamsOnIsolate,
      <String, dynamic>{
        'requestedCount': requestedCount,
        'players': players.map((player) => player.toMap()).toList(),
      },
    );

    return rawTeams
        .map(
          (team) => GeneratedTeam.fromMap(
            (team as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }
}

List<Map<String, dynamic>> _generateTeamsOnIsolate(Map<String, dynamic> payload) {
  final requestedCount = payload['requestedCount'] as int? ?? 20;
  final rawPlayers = (payload['players'] as List<dynamic>? ?? const [])
      .whereType<Map>()
      .map((player) => FantasyPlayer.fromMap(player.cast<String, dynamic>()))
      .toList();

  final random = math.Random(requestedCount + rawPlayers.length);
  final usedKeys = <String>{};
  final usedCaptainPairs = <String>{};
  final exposure = <String, int>{
    for (final player in rawPlayers) player.id: 0,
  };
  final rolePatterns = _buildRolePatterns();
  final topFive = [...rawPlayers]
    ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));
  final topFivePlayers = topFive.take(5).toList();
  final teams = <Map<String, dynamic>>[];

  var attempts = 0;
  final maxAttempts = requestedCount * 900;

  while (teams.length < requestedCount && attempts < maxAttempts) {
    attempts++;
    final pattern = rolePatterns[random.nextInt(rolePatterns.length)];
    final selected = <FantasyPlayer>[];
    final teamCounts = <String, int>{};
    var failed = false;

    for (final entry in pattern.entries) {
      final pool = rawPlayers.where((player) => player.role == entry.key).toList();
      final picked = _pickPlayersForRole(
        pool: pool,
        count: entry.value,
        selected: selected,
        exposure: exposure,
        teamCounts: teamCounts,
        random: random,
      );

      if (picked.length != entry.value) {
        failed = true;
        break;
      }

      selected.addAll(picked);
    }

    if (failed || !_isValidTeam(selected)) {
      continue;
    }

    final teamKey = (selected.map((player) => player.id).toList()..sort()).join('|');
    if (!usedKeys.add(teamKey)) {
      continue;
    }

    final leaders = _pickLeadershipPair(
      team: selected,
      globalTopFive: topFivePlayers,
      usedPairs: usedCaptainPairs,
      teamIndex: teams.length,
    );

    for (final player in selected) {
      exposure[player.id] = (exposure[player.id] ?? 0) + 1;
    }

    teams.add(
      GeneratedTeam(
        id: 'generated-${teams.length + 1}',
        teamNumber: teams.length + 1,
        players: [...selected]
          ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore)),
        captainId: leaders.captainId,
        viceCaptainId: leaders.viceCaptainId,
      ).toMap(),
    );
  }

  return teams;
}

List<FantasyPlayer> _pickPlayersForRole({
  required List<FantasyPlayer> pool,
  required int count,
  required List<FantasyPlayer> selected,
  required Map<String, int> exposure,
  required Map<String, int> teamCounts,
  required math.Random random,
}) {
  final picked = <FantasyPlayer>[];
  final remaining = [...pool];

  while (picked.length < count && remaining.isNotEmpty) {
    final candidates = remaining.where((player) {
      final alreadySelected =
          selected.any((entry) => entry.id == player.id) ||
          picked.any((entry) => entry.id == player.id);
      final teamLoad = teamCounts[player.team] ?? 0;
      return !alreadySelected && teamLoad < AppConstants.maxPlayersPerRealTeam;
    }).toList();

    if (candidates.isEmpty) {
      break;
    }

    final player = _pickWeightedPlayer(
      candidates,
      exposure: exposure,
      random: random,
    );
    picked.add(player);
    remaining.removeWhere((entry) => entry.id == player.id);
    teamCounts[player.team] = (teamCounts[player.team] ?? 0) + 1;
  }

  return picked;
}

FantasyPlayer _pickWeightedPlayer(
  List<FantasyPlayer> players, {
  required Map<String, int> exposure,
  required math.Random random,
}) {
  final weights = <double>[];
  var totalWeight = 0.0;

  for (final player in players) {
    final playerExposure = exposure[player.id] ?? 0;
    final exposurePenalty = 1 / (1 + (playerExposure * 0.45));
    final creditValue = 1 + ((12 - player.credit) * 0.03);
    final variance = 0.82 + (random.nextDouble() * 0.36);
    final weight = player.projectedScore * exposurePenalty * creditValue * variance;
    totalWeight += weight;
    weights.add(weight);
  }

  var target = random.nextDouble() * totalWeight;
  for (var index = 0; index < players.length; index++) {
    target -= weights[index];
    if (target <= 0) {
      return players[index];
    }
  }

  return players.last;
}

bool _isValidTeam(List<FantasyPlayer> team) {
  if (team.length != AppConstants.maxPlayers) {
    return false;
  }

  final totalCredits =
      team.fold<double>(0, (sum, player) => sum + player.credit);
  if (totalCredits > AppConstants.maxCredits) {
    return false;
  }

  final roleCounts = <String, int>{};
  final teamCounts = <String, int>{};
  for (final player in team) {
    roleCounts[player.role] = (roleCounts[player.role] ?? 0) + 1;
    teamCounts[player.team] = (teamCounts[player.team] ?? 0) + 1;
  }

  for (final entry in AppConstants.roleLimits.entries) {
    final count = roleCounts[entry.key] ?? 0;
    if (count < entry.value.min || count > entry.value.max) {
      return false;
    }
  }

  for (final count in teamCounts.values) {
    if (count > AppConstants.maxPlayersPerRealTeam) {
      return false;
    }
  }

  return true;
}

List<Map<String, int>> _buildRolePatterns() {
  final patterns = <Map<String, int>>[];
  for (var wk = 1; wk <= 4; wk++) {
    for (var bat = 3; bat <= 6; bat++) {
      for (var ar = 1; ar <= 4; ar++) {
        for (var bowl = 3; bowl <= 6; bowl++) {
          if (wk + bat + ar + bowl == AppConstants.maxPlayers) {
            patterns.add({
              'WK': wk,
              'BAT': bat,
              'AR': ar,
              'BOWL': bowl,
            });
          }
        }
      }
    }
  }
  return patterns;
}

_LeaderPair _pickLeadershipPair({
  required List<FantasyPlayer> team,
  required List<FantasyPlayer> globalTopFive,
  required Set<String> usedPairs,
  required int teamIndex,
}) {
  final orderedTeam = [...team]
    ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));
  final captains = <FantasyPlayer>[
    ...globalTopFive.where((player) => team.any((member) => member.id == player.id)),
    ...orderedTeam.where(
      (player) => !globalTopFive.any((elite) => elite.id == player.id),
    ),
  ];

  final viceCaptains = [...captains];

  for (var captainOffset = 0; captainOffset < captains.length; captainOffset++) {
    final captain = captains[(teamIndex + captainOffset) % captains.length];
    for (var viceOffset = 1; viceOffset <= viceCaptains.length; viceOffset++) {
      final viceCaptain =
          viceCaptains[(teamIndex + captainOffset + viceOffset) % viceCaptains.length];
      if (captain.id == viceCaptain.id) {
        continue;
      }

      final key = '${captain.id}|${viceCaptain.id}';
      if (usedPairs.add(key)) {
        return _LeaderPair(captainId: captain.id, viceCaptainId: viceCaptain.id);
      }
    }
  }

  final fallbackCaptain = orderedTeam.first;
  final fallbackViceCaptain =
      orderedTeam.firstWhere((player) => player.id != fallbackCaptain.id);
  return _LeaderPair(
    captainId: fallbackCaptain.id,
    viceCaptainId: fallbackViceCaptain.id,
  );
}

class _LeaderPair {
  const _LeaderPair({
    required this.captainId,
    required this.viceCaptainId,
  });

  final String captainId;
  final String viceCaptainId;
}

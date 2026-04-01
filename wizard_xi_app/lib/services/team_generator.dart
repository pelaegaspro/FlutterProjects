import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/models.dart';

class TeamGeneratorService {
  Future<List<GeneratedTeam>> generateTeams({
    required List<FantasyPlayer> players,
    required int requestedCount,
    ExposureConfig? exposureConfig,
    int? seed,
  }) async {
    final request = TeamGenerationRequest(
      players: players,
      requestedCount: requestedCount,
      exposureConfig: exposureConfig ?? ExposureConfig.smartDefaults(players),
      seed: seed ?? buildDeterministicSeed(players, requestedCount),
    );

    final rawTeams = await compute(
      generateTeamsDeterministic,
      request.toMap(),
    );

    return rawTeams
        .map((item) => GeneratedTeam.fromMap((item as Map).cast<String, dynamic>()))
        .toList();
  }
}

class TeamGenerationRequest {
  const TeamGenerationRequest({
    required this.players,
    required this.requestedCount,
    required this.exposureConfig,
    required this.seed,
  });

  final List<FantasyPlayer> players;
  final int requestedCount;
  final ExposureConfig exposureConfig;
  final int seed;

  Map<String, dynamic> toMap() => {
        'players': players.map((player) => player.toMap()).toList(),
        'requestedCount': requestedCount,
        'exposureConfig': exposureConfig.toMap(),
        'seed': seed,
      };

  factory TeamGenerationRequest.fromMap(Map<String, dynamic> map) {
    return TeamGenerationRequest(
      players: (map['players'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => FantasyPlayer.fromMap(item.cast<String, dynamic>()))
          .toList(),
      requestedCount: map['requestedCount'] as int? ?? 20,
      exposureConfig: ExposureConfig.fromMap(
        (map['exposureConfig'] as Map<dynamic, dynamic>? ?? const {})
            .cast<String, dynamic>(),
      ),
      seed: map['seed'] as int? ?? 0,
    );
  }
}

class ExposureTracker {
  final Map<String, int> counts = <String, int>{};

  int getCount(String playerId) => counts[playerId] ?? 0;

  int maxAllowedForPlayer({
    required FantasyPlayer player,
    required ExposureConfig config,
    required int totalTeams,
  }) {
    final percent = config.maxExposureFor(player).clamp(0, 100);
    return math.max(1, ((totalTeams * percent) / 100).floor());
  }

  bool canUsePlayer({
    required FantasyPlayer player,
    required ExposureConfig config,
    required int totalTeams,
  }) {
    return getCount(player.id) <
        maxAllowedForPlayer(
          player: player,
          config: config,
          totalTeams: totalTeams,
        );
  }

  bool canCommitTeam({
    required List<FantasyPlayer> team,
    required ExposureConfig config,
    required int totalTeams,
  }) {
    for (final player in team) {
      final projectedCount = getCount(player.id) + 1;
      final maxAllowed = maxAllowedForPlayer(
        player: player,
        config: config,
        totalTeams: totalTeams,
      );
      if (projectedCount > maxAllowed) {
        return false;
      }
    }
    return true;
  }

  void commitTeam(List<FantasyPlayer> team) {
    for (final player in team) {
      counts[player.id] = getCount(player.id) + 1;
    }
  }
}

List<Map<String, dynamic>> generateTeamsDeterministic(Map<String, dynamic> payload) {
  final request = TeamGenerationRequest.fromMap(payload);
  final players = [...request.players]
    ..sort((a, b) {
      final scoreCompare = b.projectedScore.compareTo(a.projectedScore);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.id.compareTo(b.id);
    });

  if (players.length < AppConstants.maxPlayers) {
    return const [];
  }

  final random = math.Random(request.seed);
  final tracker = ExposureTracker();
  final generatedTeams = <Map<String, dynamic>>[];
  final seenKeys = <String>{};
  final usedCaptainPairs = <String>{};
  final playersByRole = <String, List<FantasyPlayer>>{
    for (final role in AppConstants.roleOrder)
      role: players.where((player) => player.role == role).toList(),
  };
  final rolePatterns = _buildRolePatterns();
  final maxAttempts = math.max(5000, request.requestedCount * 250);
  var attempts = 0;

  while (generatedTeams.length < request.requestedCount && attempts < maxAttempts) {
    attempts++;
    final pattern = rolePatterns[random.nextInt(rolePatterns.length)];
    final candidateTeam = _buildCandidateTeam(
      playersByRole: playersByRole,
      rolePattern: pattern,
      tracker: tracker,
      exposureConfig: request.exposureConfig,
      totalTeams: request.requestedCount,
      random: random,
    );

    if (candidateTeam == null || !isValidFantasyTeam(candidateTeam)) {
      continue;
    }

    final teamKey = buildStableTeamKey(candidateTeam);
    if (!seenKeys.add(teamKey)) {
      continue;
    }

    if (!tracker.canCommitTeam(
      team: candidateTeam,
      config: request.exposureConfig,
      totalTeams: request.requestedCount,
    )) {
      continue;
    }

    final leaders = assignCaptainViceCaptain(
      team: candidateTeam,
      usedPairs: usedCaptainPairs,
      random: random,
    );

    tracker.commitTeam(candidateTeam);

    generatedTeams.add(
      GeneratedTeam(
        id: 'team-${generatedTeams.length + 1}',
        teamNumber: generatedTeams.length + 1,
        players: [...candidateTeam]
          ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore)),
        captainId: leaders.captainId,
        viceCaptainId: leaders.viceCaptainId,
      ).toMap(),
    );
  }

  return generatedTeams;
}

List<FantasyPlayer>? _buildCandidateTeam({
  required Map<String, List<FantasyPlayer>> playersByRole,
  required Map<String, int> rolePattern,
  required ExposureTracker tracker,
  required ExposureConfig exposureConfig,
  required int totalTeams,
  required math.Random random,
}) {
  final selected = <FantasyPlayer>[];
  final selectedIds = <String>{};
  final teamCounts = <String, int>{};
  var currentCredits = 0.0;

  for (final role in AppConstants.roleOrder) {
    final requiredCount = rolePattern[role] ?? 0;
    for (var slot = 0; slot < requiredCount; slot++) {
      final candidate = _pickCandidateForRole(
        role: role,
        playersByRole: playersByRole,
        rolePattern: rolePattern,
        selected: selected,
        selectedIds: selectedIds,
        teamCounts: teamCounts,
        currentCredits: currentCredits,
        tracker: tracker,
        exposureConfig: exposureConfig,
        totalTeams: totalTeams,
        random: random,
      );

      if (candidate == null) {
        return null;
      }

      selected.add(candidate);
      selectedIds.add(candidate.id);
      teamCounts[candidate.team] = (teamCounts[candidate.team] ?? 0) + 1;
      currentCredits += candidate.credit;
    }
  }

  return selected;
}

FantasyPlayer? _pickCandidateForRole({
  required String role,
  required Map<String, List<FantasyPlayer>> playersByRole,
  required Map<String, int> rolePattern,
  required List<FantasyPlayer> selected,
  required Set<String> selectedIds,
  required Map<String, int> teamCounts,
  required double currentCredits,
  required ExposureTracker tracker,
  required ExposureConfig exposureConfig,
  required int totalTeams,
  required math.Random random,
}) {
  final pool = playersByRole[role] ?? const [];
  final eligible = <_WeightedPlayer>[];

  for (final player in pool) {
    if (selectedIds.contains(player.id)) {
      continue;
    }
    if ((teamCounts[player.team] ?? 0) >= AppConstants.maxPlayersPerRealTeam) {
      continue;
    }
    if (!tracker.canUsePlayer(
      player: player,
      config: exposureConfig,
      totalTeams: totalTeams,
    )) {
      continue;
    }
    if (!_fitsBudgetAfterSelection(
      candidate: player,
      playersByRole: playersByRole,
      rolePattern: rolePattern,
      selected: selected,
      selectedIds: selectedIds,
      currentCredits: currentCredits,
    )) {
      continue;
    }

    final exposureHeadroom = tracker.maxAllowedForPlayer(
          player: player,
          config: exposureConfig,
          totalTeams: totalTeams,
        ) -
        tracker.getCount(player.id);
    final weight = (player.projectedScore * 10) +
        (exposureHeadroom * 2.5) +
        ((12 - player.credit) * 1.4) +
        random.nextDouble();
    eligible.add(_WeightedPlayer(player: player, weight: weight));
  }

  if (eligible.isEmpty) {
    return null;
  }

  eligible.sort((a, b) => b.weight.compareTo(a.weight));
  final sample = eligible.take(math.min(eligible.length, 6)).toList();
  final totalWeight = sample.fold<double>(0, (sum, item) => sum + item.weight);
  var target = random.nextDouble() * totalWeight;

  for (final item in sample) {
    target -= item.weight;
    if (target <= 0) {
      return item.player;
    }
  }

  return sample.first.player;
}

bool _fitsBudgetAfterSelection({
  required FantasyPlayer candidate,
  required Map<String, List<FantasyPlayer>> playersByRole,
  required Map<String, int> rolePattern,
  required List<FantasyPlayer> selected,
  required Set<String> selectedIds,
  required double currentCredits,
}) {
  final projectedCredits = currentCredits + candidate.credit;
  if (projectedCredits > AppConstants.maxCredits) {
    return false;
  }

  final blockedIds = {...selectedIds, candidate.id};
  var minimumCompletionCredits = 0.0;

  for (final role in AppConstants.roleOrder) {
    final alreadySelectedForRole = selected.where((player) => player.role == role).length +
        (candidate.role == role ? 1 : 0);
    final remainingNeeded = (rolePattern[role] ?? 0) - alreadySelectedForRole;

    if (remainingNeeded <= 0) {
      continue;
    }

    final available = [...(playersByRole[role] ?? const <FantasyPlayer>[])]
      ..removeWhere((player) => blockedIds.contains(player.id))
      ..sort((a, b) => a.credit.compareTo(b.credit));

    if (available.length < remainingNeeded) {
      return false;
    }

    for (var index = 0; index < remainingNeeded; index++) {
      minimumCompletionCredits += available[index].credit;
    }
  }

  return projectedCredits + minimumCompletionCredits <= AppConstants.maxCredits;
}

bool isValidFantasyTeam(List<FantasyPlayer> team) {
  if (team.length != AppConstants.maxPlayers) {
    return false;
  }

  final credits = team.fold<double>(0, (sum, player) => sum + player.credit);
  if (credits > AppConstants.maxCredits) {
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

String buildStableTeamKey(List<FantasyPlayer> team) {
  final ids = team.map((player) => player.id).toList()..sort();
  return ids.join('|');
}

LeaderPair assignCaptainViceCaptain({
  required List<FantasyPlayer> team,
  required Set<String> usedPairs,
  required math.Random random,
}) {
  final sorted = [...team]
    ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));
  final pool = sorted.take(math.min(5, sorted.length)).toList()..shuffle(random);

  for (var captainIndex = 0; captainIndex < pool.length; captainIndex++) {
    for (var viceIndex = 0; viceIndex < pool.length; viceIndex++) {
      if (captainIndex == viceIndex) {
        continue;
      }

      final key = '${pool[captainIndex].id}|${pool[viceIndex].id}';
      if (usedPairs.add(key)) {
        return LeaderPair(
          captainId: pool[captainIndex].id,
          viceCaptainId: pool[viceIndex].id,
        );
      }
    }
  }

  return LeaderPair(
    captainId: pool.first.id,
    viceCaptainId: pool[1].id,
  );
}

int buildDeterministicSeed(List<FantasyPlayer> players, int requestedCount) {
  var hash = requestedCount;
  final sortedIds = players.map((player) => player.id).toList()..sort();
  for (final id in sortedIds) {
    hash = 0x1fffffff & (hash + id.hashCode);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= (hash >> 6);
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= (hash >> 11);
  hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  return hash;
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

class LeaderPair {
  const LeaderPair({
    required this.captainId,
    required this.viceCaptainId,
  });

  final String captainId;
  final String viceCaptainId;
}

class _WeightedPlayer {
  const _WeightedPlayer({
    required this.player,
    required this.weight,
  });

  final FantasyPlayer player;
  final double weight;
}

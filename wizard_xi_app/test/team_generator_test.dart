import 'package:flutter_test/flutter_test.dart';

import 'package:wizard_xi_app/models/models.dart';
import 'package:wizard_xi_app/services/demo_data_service.dart';
import 'package:wizard_xi_app/services/team_generator.dart';

void main() {
  group('Exposure config', () {
    final players = DemoDataService.playersByMatch['demo-match-1']!;
    final target = players.first;

    test('global cap clamps smart defaults', () {
      final config = ExposureConfig.fromPlayers(
        players: players,
        globalExposurePercent: 60,
      );

      for (final player in players) {
        expect(config.maxExposureFor(player), lessThanOrEqualTo(60));
      }
    });

    test('clamp precedence matches exact matrix cases', () {
      final noOverride = ExposureConfig.fromPlayers(
        players: players,
        globalExposurePercent: 70,
      );
      final overrideAboveGlobal = ExposureConfig.fromPlayers(
        players: players,
        globalExposurePercent: 70,
        overrides: {target.id: 80},
      );
      final overrideBelowGlobal = ExposureConfig.fromPlayers(
        players: players,
        globalExposurePercent: 70,
        overrides: {target.id: 40},
      );
      final tightGlobal = ExposureConfig.fromPlayers(
        players: players,
        globalExposurePercent: 30,
        overrides: {target.id: 50},
      );

      expect(noOverride.maxExposureFor(target), lessThanOrEqualTo(70));
      expect(overrideAboveGlobal.maxExposureFor(target), 70);
      expect(overrideBelowGlobal.maxExposureFor(target), 40);
      expect(tightGlobal.maxExposureFor(target), 30);
    });

    test('per-player override is clamped by the global cap', () {
      final config = ExposureConfig.fromPlayers(
        players: players,
        globalExposurePercent: 40,
        overrides: {
          target.id: 90,
        },
      );

      expect(config.maxExposureFor(target), 40);
    });
  });

  group('Team generator', () {
    final players = DemoDataService.playersByMatch['demo-match-1']!;

    Map<String, int> buildCounts(List<GeneratedTeam> teams) {
      final counts = <String, int>{};
      for (final team in teams) {
        for (final player in team.players) {
          counts[player.id] = (counts[player.id] ?? 0) + 1;
        }
      }
      return counts;
    }

    test('returns only valid unique teams', () {
      final result = generateTeamsDeterministic(
        TeamGenerationRequest(
          players: players,
          requestedCount: 20,
          exposureConfig: ExposureConfig.smartDefaults(players),
          seed: 20260401,
        ).toMap(),
      );

      final teams =
          result.map((item) => GeneratedTeam.fromMap(item)).toList();
      final keys = teams.map((team) => buildStableTeamKey(team.players)).toSet();

      expect(teams.length, lessThanOrEqualTo(20));
      expect(keys.length, teams.length);
      for (final team in teams) {
        expect(isValidFantasyTeam(team.players), isTrue);
      }
    });

    test('is deterministic for the same seed and request', () {
      final request = TeamGenerationRequest(
        players: players,
        requestedCount: 12,
        exposureConfig: ExposureConfig.smartDefaults(players),
        seed: 424242,
      );

      final firstRun = generateTeamsDeterministic(request.toMap())
          .map((item) => GeneratedTeam.fromMap(item))
          .toList();
      final secondRun = generateTeamsDeterministic(request.toMap())
          .map((item) => GeneratedTeam.fromMap(item))
          .toList();

      expect(
        firstRun.map((team) => buildStableTeamKey(team.players)).toList(),
        equals(
          secondRun.map((team) => buildStableTeamKey(team.players)).toList(),
        ),
      );
      expect(
        firstRun.map((team) => '${team.captainId}|${team.viceCaptainId}').toList(),
        equals(
          secondRun.map((team) => '${team.captainId}|${team.viceCaptainId}').toList(),
        ),
      );
    });

    test('respects explicit exposure caps', () {
      final cappedPlayers = players.take(5).toList();
      final config = ExposureConfig(
        defaultMaxExposurePercent: 100,
        maxExposure: {
          for (final player in cappedPlayers) player.id: 40,
        },
      );

      final teams = generateTeamsDeterministic(
        TeamGenerationRequest(
          players: players,
          requestedCount: 10,
          exposureConfig: config,
          seed: 909090,
        ).toMap(),
      ).map((item) => GeneratedTeam.fromMap(item)).toList();

      final counts = buildCounts(teams);

      for (final player in cappedPlayers) {
        expect(counts[player.id] ?? 0, lessThanOrEqualTo(4));
      }
    });

    test('uses floor-based ceilings without off-by-one overflow', () {
      final config = ExposureConfig(
        defaultMaxExposurePercent: 33,
        maxExposure: {
          for (final player in players) player.id: 33,
        },
      );

      final teams = generateTeamsDeterministic(
        TeamGenerationRequest(
          players: players,
          requestedCount: 20,
          exposureConfig: config,
          seed: 330033,
        ).toMap(),
      ).map((item) => GeneratedTeam.fromMap(item)).toList();

      final counts = buildCounts(teams);
      for (final player in players) {
        expect(counts[player.id] ?? 0, lessThanOrEqualTo(6));
      }
    });

    test('returns partial but valid results under tight exposure', () {
      final config = ExposureConfig.fromPlayers(
        players: players,
        globalExposurePercent: 20,
      );

      final teams = generateTeamsDeterministic(
        TeamGenerationRequest(
          players: players,
          requestedCount: 20,
          exposureConfig: config,
          seed: 202620,
        ).toMap(),
      ).map((item) => GeneratedTeam.fromMap(item)).toList();

      expect(teams.length, lessThanOrEqualTo(20));
      for (final team in teams) {
        expect(isValidFantasyTeam(team.players), isTrue);
      }
    });

    test('is deterministic when overrides are present', () {
      final request = TeamGenerationRequest(
        players: players,
        requestedCount: 15,
        exposureConfig: ExposureConfig.fromPlayers(
          players: players,
          globalExposurePercent: 70,
          overrides: {
            players.first.id: 30,
            players[1].id: 40,
          },
        ),
        seed: 151515,
      );

      final firstRun = generateTeamsDeterministic(request.toMap())
          .map((item) => GeneratedTeam.fromMap(item))
          .toList();
      final secondRun = generateTeamsDeterministic(request.toMap())
          .map((item) => GeneratedTeam.fromMap(item))
          .toList();

      expect(
        firstRun.map((team) => buildStableTeamKey(team.players)).toList(),
        equals(
          secondRun.map((team) => buildStableTeamKey(team.players)).toList(),
        ),
      );
      expect(
        firstRun.map((team) => '${team.captainId}|${team.viceCaptainId}').toList(),
        equals(
          secondRun.map((team) => '${team.captainId}|${team.viceCaptainId}').toList(),
        ),
      );
    });

    test('changing only overrides changes generated output', () {
      final baseRequest = TeamGenerationRequest(
        players: players,
        requestedCount: 15,
        exposureConfig: ExposureConfig.fromPlayers(
          players: players,
          globalExposurePercent: 70,
        ),
        seed: 565656,
      );
      final overrideRequest = TeamGenerationRequest(
        players: players,
        requestedCount: 15,
        exposureConfig: ExposureConfig.fromPlayers(
          players: players,
          globalExposurePercent: 70,
          overrides: {
            players.first.id: 10,
          },
        ),
        seed: 565656,
      );

      final baseRun = generateTeamsDeterministic(baseRequest.toMap())
          .map((item) => GeneratedTeam.fromMap(item))
          .toList();
      final overrideRun = generateTeamsDeterministic(overrideRequest.toMap())
          .map((item) => GeneratedTeam.fromMap(item))
          .toList();

      expect(
        baseRun.map((team) => buildStableTeamKey(team.players)).toList(),
        isNot(
          equals(
            overrideRun.map((team) => buildStableTeamKey(team.players)).toList(),
          ),
        ),
      );
    });

    test('input order does not change generated team set', () {
      final seed = 777001;
      final forwardRequest = TeamGenerationRequest(
        players: players,
        requestedCount: 18,
        exposureConfig: ExposureConfig.fromPlayers(
          players: players,
          globalExposurePercent: 70,
        ),
        seed: seed,
      );
      final reversedRequest = TeamGenerationRequest(
        players: players.reversed.toList(),
        requestedCount: 18,
        exposureConfig: ExposureConfig.fromPlayers(
          players: players.reversed.toList(),
          globalExposurePercent: 70,
        ),
        seed: seed,
      );

      final forwardRun = generateTeamsDeterministic(forwardRequest.toMap())
          .map((item) => GeneratedTeam.fromMap(item))
          .toList();
      final reversedRun = generateTeamsDeterministic(reversedRequest.toMap())
          .map((item) => GeneratedTeam.fromMap(item))
          .toList();

      expect(
        forwardRun.map((team) => buildStableTeamKey(team.players)).toSet(),
        equals(
          reversedRun.map((team) => buildStableTeamKey(team.players)).toSet(),
        ),
      );
    });
  });
}

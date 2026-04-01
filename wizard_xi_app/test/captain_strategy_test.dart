import 'package:flutter_test/flutter_test.dart';

import 'package:wizard_xi_app/models/models.dart';
import 'package:wizard_xi_app/services/captain_strategy.dart';

void main() {
  group(
    'Captain strategy spec',
    () {
      test(
        'captain strategy is deterministic with same seed and strategy',
        () {
          final team = buildMockTeam();
          const seed = 123;

          final t1 = assignWithStrategy(
            team,
            seed,
            CaptainStrategy.balanced,
          );
          final t2 = assignWithStrategy(
            team,
            seed,
            CaptainStrategy.balanced,
          );

          expect(t1.captain, t2.captain);
          expect(t1.viceCaptain, t2.viceCaptain);
        },
      );

      test(
        'strategy does not change team composition',
        () {
          final team = buildMockTeam();
          final original = team.map((player) => player.name).toSet();

          assignWithStrategy(
            team,
            42,
            CaptainStrategy.safe,
          );

          expect(team.map((player) => player.name).toSet(), original);
        },
      );

      test(
        'strategy does not mutate input players',
        () {
          final team = buildMockTeam();
          final originalSnapshots =
              team.map((player) => player.toMap()).toList(growable: false);

          assignWithStrategy(
            team,
            42,
            CaptainStrategy.balanced,
          );

          expect(
            team.map((player) => player.toMap()).toList(growable: false),
            equals(originalSnapshots),
          );
        },
      );

      test(
        'throws if not enough players for captain selection',
        () {
          final team = buildSmallTeam(1);

          expect(
            () => assignWithStrategy(team, 1, CaptainStrategy.safe),
            throwsException,
          );
        },
      );

      test(
        'captain and vice captain must be from input team',
        () {
          final team = buildMockTeam();
          final result = assignWithStrategy(
            team,
            1,
            CaptainStrategy.balanced,
          );

          final names = team.map((player) => player.name).toSet();

          expect(names.contains(result.captain), isTrue);
          expect(names.contains(result.viceCaptain), isTrue);
        },
      );

      test(
        'safe strategy picks from top 3',
        () {
          final team = buildSortedTeam();
          final updated = assignWithStrategy(
            team,
            1,
            CaptainStrategy.safe,
          );

          final top3 = team.take(3).map((player) => player.name).toSet();

          expect(top3.contains(updated.captain), isTrue);
          expect(top3.contains(updated.viceCaptain), isTrue);
        },
      );

      test(
        'selection pool has at least 2 candidates',
        () {
          final team = buildSortedTeam();
          final result = assignWithStrategy(
            team,
            1,
            CaptainStrategy.safe,
          );

          expect(result.captain != result.viceCaptain, isTrue);
        },
      );

      test(
        'safe strategy strictly uses highest scores',
        () {
          final team = buildSortedTeam();
          final result = assignWithStrategy(
            team,
            1,
            CaptainStrategy.safe,
          );

          final sorted = [...team]
            ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));
          final top3 = sorted.take(3).map((player) => player.name).toSet();

          expect(top3.contains(result.captain), isTrue);
          expect(top3.contains(result.viceCaptain), isTrue);
        },
      );

      test(
        'aggressive strategy avoids top 3',
        () {
          final team = buildSortedTeam();
          final updated = assignWithStrategy(
            team,
            1,
            CaptainStrategy.aggressive,
          );

          final top3 = team.take(3).map((player) => player.name).toSet();

          expect(top3.contains(updated.captain), isFalse);
          expect(top3.contains(updated.viceCaptain), isFalse);
        },
      );

      test(
        'different strategy changes output with same seed',
        () {
          final team = buildMockTeam();

          final safe = assignWithStrategy(
            team,
            1,
            CaptainStrategy.safe,
          );
          final aggressive = assignWithStrategy(
            team,
            1,
            CaptainStrategy.aggressive,
          );

          expect(
            safe.captain != aggressive.captain ||
                safe.viceCaptain != aggressive.viceCaptain,
            isTrue,
          );
        },
      );

      test(
        'captain and vice captain are different',
        () {
          final team = buildMockTeam();
          final updated = assignWithStrategy(
            team,
            5,
            CaptainStrategy.balanced,
          );

          expect(updated.captain != updated.viceCaptain, isTrue);
        },
      );

      test(
        'reapplying strategy does not change result',
        () {
          final team = buildMockTeam();

          final once = assignWithStrategy(
            team,
            10,
            CaptainStrategy.balanced,
          );
          final twice = assignWithStrategy(
            team,
            10,
            CaptainStrategy.balanced,
          );

          expect(once.captain, twice.captain);
          expect(once.viceCaptain, twice.viceCaptain);
        },
      );

      test(
        'idempotent across new list instances',
        () {
          final team1 = buildMockTeam();
          final team2 = buildMockTeam();

          final r1 = assignWithStrategy(
            team1,
            10,
            CaptainStrategy.balanced,
          );
          final r2 = assignWithStrategy(
            team2,
            10,
            CaptainStrategy.balanced,
          );

          expect(r1.captain, r2.captain);
          expect(r1.viceCaptain, r2.viceCaptain);
        },
      );
    },
  );
}

List<FantasyPlayer> buildMockTeam() {
  return [
    _player('p1', 'Virat Kohli', 98),
    _player('p2', 'Rohit Sharma', 94),
    _player('p3', 'Jasprit Bumrah', 92, role: 'BOWL'),
    _player('p4', 'Travis Head', 88),
    _player('p5', 'Hardik Pandya', 86, role: 'AR'),
    _player('p6', 'Ravindra Jadeja', 83, role: 'AR'),
    _player('p7', 'KL Rahul', 81, role: 'WK'),
    _player('p8', 'Shubman Gill', 79),
    _player('p9', 'Mitchell Starc', 77, role: 'BOWL'),
    _player('p10', 'Adam Zampa', 74, role: 'BOWL'),
    _player('p11', 'Axar Patel', 72, role: 'AR'),
  ];
}

List<FantasyPlayer> buildSortedTeam() {
  final team = buildMockTeam();
  team.sort((a, b) => b.projectedScore.compareTo(a.projectedScore));
  return team;
}

List<FantasyPlayer> buildSmallTeam(int size) {
  return buildSortedTeam().take(size).toList();
}

FantasyPlayer _player(
  String id,
  String name,
  double score, {
  String team = 'Demo XI',
  String role = 'BAT',
  double credit = 9.0,
}) {
  return FantasyPlayer(
    id: id,
    name: name,
    team: team,
    role: role,
    credit: credit,
    last5Avg: score,
    venueAvg: score,
    opponentAvg: score,
  );
}

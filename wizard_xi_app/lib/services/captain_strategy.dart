import 'dart:math';

import '../models/models.dart';

enum CaptainStrategy {
  safe,
  balanced,
  aggressive,
}

class CaptainAssignment {
  const CaptainAssignment(this.captain, this.viceCaptain);

  final String captain;
  final String viceCaptain;
}

CaptainAssignment assignWithStrategy(
  List<FantasyPlayer> team,
  int seed,
  CaptainStrategy strategy,
) {
  if (team.length < 2) {
    throw Exception('Not enough players for captain selection');
  }

  final sorted = [...team]
    ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));

  late final List<FantasyPlayer> pool;
  switch (strategy) {
    case CaptainStrategy.safe:
      pool = sorted.take(3).toList();
      break;
    case CaptainStrategy.balanced:
      pool = sorted.take(5).toList();
      break;
    case CaptainStrategy.aggressive:
      pool = sorted.skip(3).take(5).toList();
      break;
  }

  if (pool.length < 2) {
    throw Exception('Insufficient candidate pool for strategy');
  }

  final shuffledPool = [...pool]..shuffle(Random(seed));
  final captain = shuffledPool[0].name;
  final viceCaptain = shuffledPool[1].name;

  if (captain == viceCaptain) {
    throw Exception('Captain and Vice Captain cannot be the same');
  }

  return CaptainAssignment(captain, viceCaptain);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_provider.dart';

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>((ref, matchId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getLeaderboard(matchId);
});

final leaderboardStreamProvider = StreamProvider.family<List<LeaderboardEntry>, String>((ref, matchId) {
  final service = ref.watch(supabaseServiceProvider);
  return service.watchLeaderboard(matchId);
});

final topThreeProvider = Provider.family<List<LeaderboardEntry>, String>((ref, matchId) {
  final leaderboard = ref.watch(leaderboardStreamProvider(matchId));
  return leaderboard.maybeWhen(
    data: (entries) => entries.take(3).toList(),
    orElse: () => const [],
  );
});

final userRankProvider = Provider.family<int?, (String, String)>((ref, params) {
  final matchId = params.$1;
  final userId = params.$2;
  final leaderboard = ref.watch(leaderboardStreamProvider(matchId));

  return leaderboard.maybeWhen(
    data: (entries) {
      for (final entry in entries) {
        if (entry.userId == userId) {
          return entry.rank;
        }
      }
      return null;
    },
    orElse: () => null,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/smart_api_service.dart';

final smartAPIServiceProvider = Provider<SmartAPIService>((ref) => SmartAPIService());

final liveMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.watch(smartAPIServiceProvider);
  return service.fetchLiveMatches();
});

final upcomingMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.watch(smartAPIServiceProvider);
  return service.fetchUpcomingMatches();
});

final completedMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.watch(smartAPIServiceProvider);
  return service.fetchCompletedMatches();
});

final allMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final service = ref.watch(smartAPIServiceProvider);
  return service.fetchAllMatches();
});

final matchPlayersProvider = FutureProvider.family<List<Player>, String>((ref, matchId) async {
  final service = ref.watch(smartAPIServiceProvider);
  return service.fetchMatchPlayers(matchId);
});

final matchDetailsProvider = FutureProvider.family<Match?, String>((ref, matchId) async {
  final service = ref.watch(smartAPIServiceProvider);
  return service.fetchMatchById(matchId);
});

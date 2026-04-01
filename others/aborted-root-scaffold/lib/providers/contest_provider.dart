import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'auth_provider.dart';

final contestsProvider = FutureProvider.family<List<Contest>, String?>((ref, matchId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getContests(matchId: matchId);
});

final joinedContestCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getJoinedContestCount(userId);
});

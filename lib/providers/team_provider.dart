import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/models.dart';
import 'auth_provider.dart';

final userTeamsProvider = FutureProvider.family<List<Team>, String>((ref, userId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getUserTeams(userId);
});

final teamDetailsProvider = FutureProvider.family<Team?, String>((ref, teamId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getTeamById(teamId);
});

final teamDraftProvider = NotifierProvider<TeamDraftController, TeamDraft>(
  TeamDraftController.new,
);

final totalCreditsProvider = Provider<int>((ref) {
  return ref.watch(teamDraftProvider).totalCredits;
});

final isTeamValidProvider = Provider<bool>((ref) {
  return ref.watch(teamDraftProvider).isValid;
});

class TeamDraftController extends Notifier<TeamDraft> {
  @override
  TeamDraft build() => TeamDraft.empty;

  void startDraft(String matchId) {
    if (state.matchId != matchId) {
      state = TeamDraft(matchId: matchId);
    }
  }

  void togglePlayer(Player player) {
    final players = [...state.players];
    final existingIndex = players.indexWhere((entry) => entry.id == player.id);

    if (existingIndex >= 0) {
      players.removeAt(existingIndex);
      final removedCaptain = state.captainId == player.id;
      final removedViceCaptain = state.viceCaptainId == player.id;
      state = state.copyWith(
        players: players,
        clearCaptain: removedCaptain,
        clearViceCaptain: removedViceCaptain,
      );
      return;
    }

    if (players.length >= AppConstants.maxPlayers) {
      return;
    }

    final projectedCredits = state.totalCredits + player.credits;
    if (projectedCredits > AppConstants.maxCredits) {
      return;
    }

    final sameTeamPlayers = players.where((entry) => entry.team == player.team).length;
    if (sameTeamPlayers >= AppConstants.maxPlayersPerTeam) {
      return;
    }

    players.add(player);
    state = state.copyWith(players: players);
  }

  void selectCaptain(String playerId) {
    if (state.viceCaptainId == playerId) {
      return;
    }
    state = state.copyWith(captainId: playerId);
  }

  void selectViceCaptain(String playerId) {
    if (state.captainId == playerId) {
      return;
    }
    state = state.copyWith(viceCaptainId: playerId);
  }

  void clear() {
    state = TeamDraft.empty;
  }
}

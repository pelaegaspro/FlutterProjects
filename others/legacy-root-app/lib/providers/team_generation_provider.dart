import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'fantasy_providers.dart';

final teamGenerationControllerProvider = StateNotifierProvider.family<
    TeamGenerationController, TeamGenerationState, String>(
  (ref, matchId) => TeamGenerationController(ref, matchId),
);

class TeamGenerationController extends StateNotifier<TeamGenerationState> {
  TeamGenerationController(this._ref, this.matchId)
      : super(const TeamGenerationState());

  final Ref _ref;
  final String matchId;

  void setRequestedCount(int count) {
    state = state.copyWith(
      requestedCount: count,
      clearError: true,
      clearWarning: true,
    );
  }

  Future<void> generateTeams(List<FantasyPlayer> players) async {
    state = state.copyWith(
      isGenerating: true,
      clearError: true,
      clearWarning: true,
    );

    try {
      final generated = await _ref.read(teamGeneratorServiceProvider).generateTeams(
            players: players,
            requestedCount: state.requestedCount,
          );

      final warning = generated.length < state.requestedCount
          ? 'Generated ${generated.length} unique teams out of ${state.requestedCount}. Add more player variety to unlock additional combinations.'
          : null;

      state = state.copyWith(
        isGenerating: false,
        generatedTeams: generated,
        currentBatchIndex: 0,
        warningMessage: warning,
      );
    } catch (error) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'Team generation failed: $error',
      );
    }
  }

  void nextBatch() {
    if (state.currentBatchIndex >= state.totalBatches - 1) {
      return;
    }
    state = state.copyWith(currentBatchIndex: state.currentBatchIndex + 1);
  }

  void previousBatch() {
    if (state.currentBatchIndex <= 0) {
      return;
    }
    state = state.copyWith(currentBatchIndex: state.currentBatchIndex - 1);
  }

  Future<void> copyTeam(GeneratedTeam team) async {
    await Clipboard.setData(ClipboardData(text: team.toCopyText()));
  }

  Future<void> copyCurrentBatch() async {
    final batchText = state.currentBatch.map((team) => team.toCopyText()).join('\n\n');
    await Clipboard.setData(ClipboardData(text: batchText));
  }
}

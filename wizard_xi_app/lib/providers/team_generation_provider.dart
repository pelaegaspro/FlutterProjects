import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/team_generator.dart';
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

  void setGlobalExposurePercent(double value) {
    state = state.copyWith(
      globalExposurePercent: value,
      clearError: true,
      clearWarning: true,
    );
  }

  void setPlayerExposureOverride({
    required String playerId,
    required double exposurePercent,
  }) {
    state = state.copyWith(
      exposureOverrides: {
        ...state.exposureOverrides,
        playerId: exposurePercent,
      },
      clearError: true,
      clearWarning: true,
    );
  }

  void clearPlayerExposureOverride(String playerId) {
    final nextOverrides = {...state.exposureOverrides}..remove(playerId);
    state = state.copyWith(
      exposureOverrides: nextOverrides,
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
      final exposureConfig = _buildExposureConfig(players);
      final seed = Object.hash(
        matchId,
        state.requestedCount,
        state.globalExposurePercent.round(),
        buildDeterministicSeed(players, state.requestedCount),
      );

      final generated = await _ref.read(teamGeneratorServiceProvider).generateTeams(
            players: players,
            requestedCount: state.requestedCount,
            exposureConfig: exposureConfig,
            seed: seed,
          );

      final warning = generated.length < state.requestedCount
          ? 'Only ${generated.length} of ${state.requestedCount} teams were generated because exposure, role, or credit constraints became too tight.'
          : null;

      state = state.copyWith(
        isGenerating: false,
        generatedTeams: generated,
        lastGenerationSeed: seed,
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
    final text = state.currentBatch.map((team) => team.toCopyText()).join('\n\n');
    await Clipboard.setData(ClipboardData(text: text));
  }

  ExposureConfig _buildExposureConfig(List<FantasyPlayer> players) {
    return ExposureConfig.fromPlayers(
      players: players,
      globalExposurePercent: state.globalExposurePercent,
      overrides: state.exposureOverrides,
    );
  }
}

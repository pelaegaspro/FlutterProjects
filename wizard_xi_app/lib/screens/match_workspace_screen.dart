import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/fantasy_providers.dart';
import '../providers/team_generation_provider.dart';
import '../widgets/team_card.dart';
import 'dream11_recreate_screen.dart';

class MatchWorkspaceScreen extends ConsumerWidget {
  const MatchWorkspaceScreen({
    super.key,
    required this.match,
  });

  final FantasyMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(matchPlayersProvider(match.id));
    final generationState =
        ref.watch(teamGenerationControllerProvider(match.id));
    final controller =
        ref.read(teamGenerationControllerProvider(match.id).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(match.title),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: playersAsync.when(
            data: (players) {
              final exposureConfig = ExposureConfig.fromPlayers(
                players: players,
                globalExposurePercent: generationState.globalExposurePercent,
                overrides: generationState.exposureOverrides,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _GeneratorHeader(
                    match: match,
                    players: players,
                    requestedCount: generationState.requestedCount,
                    globalExposurePercent:
                        generationState.globalExposurePercent,
                    isGenerating: generationState.isGenerating,
                    onCountSelected: controller.setRequestedCount,
                    onExposureChanged: controller.setGlobalExposurePercent,
                    onGenerate: players.isEmpty
                        ? null
                        : () => controller.generateTeams(players),
                  ),
                  const SizedBox(height: 16),
                  _ExposureOverrideCard(
                    players: players,
                    exposureConfig: exposureConfig,
                    overrides: generationState.exposureOverrides,
                    globalExposurePercent:
                        generationState.globalExposurePercent,
                    onSetOverride: (playerId, exposurePercent) {
                      controller.setPlayerExposureOverride(
                        playerId: playerId,
                        exposurePercent: exposurePercent,
                      );
                    },
                    onClearOverride: controller.clearPlayerExposureOverride,
                  ),
                  const SizedBox(height: 16),
                  if (generationState.errorMessage != null) ...[
                    _MessageCard(
                      color: AppColors.danger,
                      message: generationState.errorMessage!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (generationState.warningMessage != null) ...[
                    _MessageCard(
                      color: AppColors.secondaryAccent,
                      message: generationState.warningMessage!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (generationState.generatedTeams.isNotEmpty) ...[
                    _ExposureSummaryCard(
                      teams: generationState.generatedTeams,
                      players: players,
                      exposureConfig: exposureConfig,
                      requestedCount: generationState.requestedCount,
                      generationSeed: generationState.lastGenerationSeed,
                    ),
                    const SizedBox(height: 16),
                    _BatchToolbar(
                      state: generationState,
                      onPrevious: controller.previousBatch,
                      onNext: controller.nextBatch,
                      onCopyBatch: () async {
                        await controller.copyCurrentBatch();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Current batch copied')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ...generationState.currentBatch.map(
                      (team) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TeamCard(
                          team: team,
                          onCopy: () async {
                            await controller.copyTeam(team);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Team ${team.teamNumber} copied'),
                                ),
                              );
                            }
                          },
                          onCreateInDream11: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => Dream11RecreateScreen(
                                  match: match,
                                  team: team,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ] else ...[
                    const _EmptyGenerationCard(),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load player pool.\n$error',
                  style: const TextStyle(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratorHeader extends StatelessWidget {
  const _GeneratorHeader({
    required this.match,
    required this.players,
    required this.requestedCount,
    required this.globalExposurePercent,
    required this.isGenerating,
    required this.onCountSelected,
    required this.onExposureChanged,
    required this.onGenerate,
  });

  final FantasyMatch match;
  final List<FantasyPlayer> players;
  final int requestedCount;
  final double globalExposurePercent;
  final bool isGenerating;
  final ValueChanged<int> onCountSelected;
  final ValueChanged<double> onExposureChanged;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    final topScore = players.isEmpty ? 0.0 : players.first.projectedScore;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${players.length} players loaded - Top projected score ${topScore.toStringAsFixed(1)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI score = (last5Avg x 0.4) + (venueAvg x 0.3) + (opponentAvg x 0.3)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.teamCountOptions.map((count) {
                return ChoiceChip(
                  label: Text('$count Teams'),
                  selected: count == requestedCount,
                  onSelected: (_) => onCountSelected(count),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardMuted,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Max Player Exposure (%)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${globalExposurePercent.round()}%',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This is a global ceiling. Smart defaults and optional player overrides can only lower a player below this cap.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  Slider(
                    value: globalExposurePercent,
                    min: 10,
                    max: 100,
                    divisions: 9,
                    label: '${globalExposurePercent.round()}%',
                    onChanged: isGenerating ? null : onExposureChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isGenerating ? null : onGenerate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isGenerating ? 'Generating Teams...' : 'Generate Teams',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (isGenerating) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExposureOverrideCard extends StatelessWidget {
  const _ExposureOverrideCard({
    required this.players,
    required this.exposureConfig,
    required this.overrides,
    required this.globalExposurePercent,
    required this.onSetOverride,
    required this.onClearOverride,
  });

  final List<FantasyPlayer> players;
  final ExposureConfig exposureConfig;
  final Map<String, double> overrides;
  final double globalExposurePercent;
  final void Function(String playerId, double exposurePercent) onSetOverride;
  final void Function(String playerId) onClearOverride;

  @override
  Widget build(BuildContext context) {
    final topPlayers = [...players]
      ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Player Exposure Overrides',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap a player to set a lower cap than the global limit. If you clear the override, the player falls back to the smart default under the global ceiling.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: topPlayers.take(8).map((player) {
                final override = overrides[player.id];
                final effective = exposureConfig.maxExposureFor(player);
                return ActionChip(
                  label: Text(
                    '${player.name} ${effective.round()}%',
                  ),
                  avatar: override != null
                      ? const Icon(Icons.tune_rounded, size: 18)
                      : const Icon(Icons.person_outline_rounded, size: 18),
                  onPressed: () => _showOverrideSheet(
                    context: context,
                    player: player,
                    globalExposurePercent: globalExposurePercent,
                    initialValue: override ?? effective,
                    hasOverride: override != null,
                    onSave: (value) => onSetOverride(player.id, value),
                    onClear: () => onClearOverride(player.id),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOverrideSheet({
    required BuildContext context,
    required FantasyPlayer player,
    required double globalExposurePercent,
    required double initialValue,
    required bool hasOverride,
    required ValueChanged<double> onSave,
    required VoidCallback onClear,
  }) async {
    var localValue = initialValue;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final effective = localValue > globalExposurePercent
                ? globalExposurePercent
                : localValue;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${player.role} • ${player.team} • Effective cap ${effective.round()}%',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: localValue,
                    min: 10,
                    max: 100,
                    divisions: 9,
                    label: '${localValue.round()}%',
                    onChanged: (value) {
                      setModalState(() {
                        localValue = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Overrides can only lower a player beneath the global cap. Anything above the global cap is automatically clamped.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (hasOverride)
                        TextButton(
                          onPressed: () {
                            onClear();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Clear Override'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          onSave(localValue);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ExposureSummaryCard extends StatelessWidget {
  const _ExposureSummaryCard({
    required this.teams,
    required this.players,
    required this.exposureConfig,
    required this.requestedCount,
    required this.generationSeed,
  });

  final List<GeneratedTeam> teams;
  final List<FantasyPlayer> players;
  final ExposureConfig exposureConfig;
  final int requestedCount;
  final int? generationSeed;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final team in teams) {
      for (final player in team.players) {
        counts[player.id] = (counts[player.id] ?? 0) + 1;
      }
    }

    final sortedPlayers = [...players]
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    final previewPlayers = sortedPlayers.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exposure Summary',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Top generated players across ${teams.length} teams. Format: actual appearances / max allowed from the requested team count.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (generationSeed != null) ...[
              const SizedBox(height: 8),
              Text(
                'Seed: $generationSeed',
                style: const TextStyle(
                  color: AppColors.secondaryAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...previewPlayers.map((player) {
              final actual = counts[player.id] ?? 0;
              final maxAllowed = ((requestedCount *
                          exposureConfig.maxExposureFor(player)) /
                      100)
                  .floor();
              final safeMaxAllowed = maxAllowed < 1 ? 1 : maxAllowed;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$actual/$safeMaxAllowed',
                      style: const TextStyle(
                        color: AppColors.secondaryAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BatchToolbar extends StatelessWidget {
  const _BatchToolbar({
    required this.state,
    required this.onPrevious,
    required this.onNext,
    required this.onCopyBatch,
  });

  final TeamGenerationState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCopyBatch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch ${state.currentBatchIndex + 1} of ${state.totalBatches}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Teams ${state.pageStart + 1}-${state.pageEnd} - ${state.generatedTeams.length} total generated',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton(
                  onPressed: state.currentBatchIndex > 0 ? onPrevious : null,
                  child: const Text('Previous Batch'),
                ),
                FilledButton.tonal(
                  onPressed: onCopyBatch,
                  child: const Text('Copy 20 Teams'),
                ),
                OutlinedButton(
                  onPressed: state.currentBatchIndex < state.totalBatches - 1
                      ? onNext
                      : null,
                  child: const Text('Next Batch'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.color,
    required this.message,
  });

  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGenerationCard extends StatelessWidget {
  const _EmptyGenerationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'No teams generated yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Set the team count, tune exposure, add optional player overrides, and generate unique combinations that respect credits, role limits, duplicate prevention, and captain rotation.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

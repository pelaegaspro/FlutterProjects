import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/match_provider.dart';
import '../providers/team_provider.dart';
import '../widgets/player_card.dart';

class PlayerSelectionScreen extends ConsumerStatefulWidget {
  final String matchId;

  const PlayerSelectionScreen({super.key, required this.matchId});

  @override
  ConsumerState<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends ConsumerState<PlayerSelectionScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(teamDraftProvider.notifier).startDraft(widget.matchId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(matchPlayersProvider(widget.matchId));
    final draft = ref.watch(teamDraftProvider);
    final selectedPlayers = draft.players;
    final validationErrors = draft.validationErrors;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Select Players'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: context.pop,
        ),
      ),
      body: playersAsync.when(
        data: (players) {
          if (players.isEmpty) {
            return const _EmptyPlayerState(
              message: 'Squads are not available yet for this match.',
            );
          }

          final groupedPlayers = _groupPlayersByRole(players);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...groupedPlayers.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.map((player) {
                            final isSelected = selectedPlayers.any((entry) => entry.id == player.id);
                            return PlayerCard(
                              player: player,
                              isSelected: isSelected,
                              onTap: () => _togglePlayer(player),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(top: BorderSide(color: AppColors.secondaryCard)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedPlayers.length}/${AppConstants.maxPlayers} Players',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        Text(
                          '${draft.totalCredits}/${AppConstants.maxCredits} Credits',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RuleChip(
                          label: 'WK ${draft.wicketKeeperCount}/1',
                          isMet: draft.wicketKeeperCount >= 1,
                        ),
                        _RuleChip(
                          label: 'BAT ${draft.batterCount}/3',
                          isMet: draft.batterCount >= 3,
                        ),
                        _RuleChip(
                          label: 'AR ${draft.allRounderCount}/1',
                          isMet: draft.allRounderCount >= 1,
                        ),
                        _RuleChip(
                          label: 'BOWL ${draft.bowlerCount}/3',
                          isMet: draft.bowlerCount >= 3,
                        ),
                      ],
                    ),
                    if (validationErrors.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          validationErrors.first,
                          style: const TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: draft.isValid
                            ? () => context.push('/captain-selection/${widget.matchId}')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        child: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const _EmptyPlayerState(
          message: 'Loading available players...',
        ),
        error: (error, _) => _EmptyPlayerState(
          message: 'Unable to load squads.\n$error',
        ),
      ),
    );
  }

  void _togglePlayer(Player player) {
    final controller = ref.read(teamDraftProvider.notifier);
    final before = ref.read(teamDraftProvider);
    controller.togglePlayer(player);
    final after = ref.read(teamDraftProvider);

    if (before.players.length == after.players.length &&
        !before.players.any((entry) => entry.id == player.id) &&
        !after.players.any((entry) => entry.id == player.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selection must stay within 11 players, 100 credits, and 7 players per team.',
          ),
        ),
      );
    }
  }

  Map<String, List<Player>> _groupPlayersByRole(List<Player> players) {
    return {
      'WK': players.where((player) => player.role == 'WK').toList(),
      'BAT': players.where((player) => player.role == 'BAT').toList(),
      'AR': players.where((player) => player.role == 'AR').toList(),
      'BOWL': players.where((player) => player.role == 'BOWL').toList(),
    };
  }
}

class _EmptyPlayerState extends StatelessWidget {
  const _EmptyPlayerState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({
    required this.label,
    required this.isMet,
  });

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMet
            ? AppColors.primaryAccent.withValues(alpha: 0.16)
            : const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isMet ? AppColors.primaryAccent : const Color(0xFFEF4444),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isMet ? AppColors.primaryAccent : const Color(0xFFFCA5A5),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../providers/team_provider.dart';

class CaptainScreen extends ConsumerStatefulWidget {
  final String matchId;

  const CaptainScreen({super.key, required this.matchId});

  @override
  ConsumerState<CaptainScreen> createState() => _CaptainScreenState();
}

class _CaptainScreenState extends ConsumerState<CaptainScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(teamDraftProvider);
    final players = draft.players;
    final matchAsync = ref.watch(matchDetailsProvider(widget.matchId));
    final user = ref.watch(currentUserProvider);

    if (draft.matchId != widget.matchId || players.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('Select Captain & VC'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Select your 11 players first before choosing captain and vice captain.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Select Captain & VC'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: context.pop,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final isCaptain = draft.captainId == player.id;
                final isViceCaptain = draft.viceCaptainId == player.id;

                return GestureDetector(
                  onTap: () => ref.read(teamDraftProvider.notifier).selectCaptain(player.id),
                  onLongPress: () => ref.read(teamDraftProvider.notifier).selectViceCaptain(player.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCaptain
                            ? AppColors.captainBadge
                            : isViceCaptain
                                ? AppColors.vcBadge
                                : AppColors.secondaryCard,
                        width: isCaptain || isViceCaptain ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  player.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${player.team} | ${player.role}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isCaptain)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _Badge(
                              label: 'C',
                              color: AppColors.captainBadge,
                            ),
                          ),
                        if (isViceCaptain)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _Badge(
                              label: 'VC',
                              color: AppColors.vcBadge,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
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
                const Text(
                  'Tap to set Captain | Long press to set Vice Captain',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: draft.captainId != null &&
                            draft.viceCaptainId != null &&
                            !_isSubmitting &&
                            user != null
                        ? () => _submitTeam(
                              user: user,
                              match: matchAsync.value,
                              draft: draft,
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Submit Team'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTeam({
    required User user,
    required Match? match,
    required TeamDraft draft,
  }) async {
    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      final now = DateTime.now();
      final teamName = match == null
          ? 'Team ${now.millisecondsSinceEpoch}'
          : '${match.teamA.split(' ').first}-${match.teamB.split(' ').first}-${now.millisecondsSinceEpoch % 10000}';

      final team = Team(
        id: '',
        userId: user.id,
        matchId: widget.matchId,
        teamName: teamName,
        players: draft.players,
        captainId: draft.captainId!,
        viceCaptainId: draft.viceCaptainId!,
        totalCredits: draft.totalCredits,
        createdAt: now,
      );

      await service.createTeam(team);
      ref.invalidate(userTeamsProvider(user.id));
      ref.read(teamDraftProvider.notifier).clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team created successfully.')),
        );
        context.go('/my-teams');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save team: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

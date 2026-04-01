import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/contest_provider.dart';
import '../providers/team_provider.dart';
import '../widgets/bottom_nav.dart';

class JoinMatchScreen extends ConsumerWidget {
  const JoinMatchScreen({
    super.key,
    this.showBottomNav = true,
  });

  final bool showBottomNav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final contestsAsync = ref.watch(contestsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Join Match',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: contestsAsync.when(
        data: (contests) {
          if (contests.isEmpty) {
            return const _JoinMatchMessageState(
              message: 'No joinable matches are available yet.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondaryCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contest.contestName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      contest.prizeDescription,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Entry: ${contest.entryFee == 0 ? 'Free' : contest.entryFee}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Max Teams: ${contest.maxTeams}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push('/leaderboard?matchId=${contest.matchId}'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.secondaryCard),
                              foregroundColor: AppColors.textPrimary,
                            ),
                            child: const Text('Leaderboard'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: user == null
                                ? null
                                : () => _joinContest(
                                      context: context,
                                      ref: ref,
                                      contest: contest,
                                      user: user,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                            ),
                            child: const Text('Join Match'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _JoinMatchMessageState(
          message: 'Unable to load joinable matches.\n$error',
        ),
      ),
      bottomNavigationBar: showBottomNav ? const BottomNavBar(currentIndex: 1) : null,
    );
  }

  Future<void> _joinContest({
    required BuildContext context,
    required WidgetRef ref,
    required Contest contest,
    required User user,
  }) async {
    final teams = await ref.read(userTeamsProvider(user.id).future);
    final eligibleTeams = teams.where((team) => team.matchId == contest.matchId).toList();

    if (!context.mounted) {
      return;
    }

    if (eligibleTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a team for this match before joining it.')),
      );
      return;
    }

    final selectedTeam = await showModalBottomSheet<Team>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select a team',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...eligibleTeams.map(
                (team) => ListTile(
                  title: Text(
                    team.teamName,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    'C: ${team.captainName} | VC: ${team.viceCaptainName}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(team),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedTeam == null || !context.mounted) {
      return;
    }

    try {
      final service = ref.read(supabaseServiceProvider);
      await service.joinContest(
        contestId: contest.id,
        teamId: selectedTeam.id,
        userId: user.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match joined successfully.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to join match: $error')),
        );
      }
    }
  }
}

class _JoinMatchMessageState extends StatelessWidget {
  const _JoinMatchMessageState({required this.message});

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

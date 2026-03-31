import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/leaderboard_provider.dart';
import '../providers/match_provider.dart';
import '../widgets/bottom_nav.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({
    super.key,
    this.matchId,
    this.showBottomNav = true,
  });

  final String? matchId;
  final bool showBottomNav;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String? _selectedMatchId;

  @override
  void initState() {
    super.initState();
    _selectedMatchId = widget.matchId;
  }

  @override
  void didUpdateWidget(covariant LeaderboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId) {
      _selectedMatchId = widget.matchId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(allMatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: matchesAsync.when(
        data: (matches) {
          final availableMatches = matches.where((match) => !match.isUpcoming).toList();
          final activeMatchId = _selectedMatchId ??
              (availableMatches.isNotEmpty ? availableMatches.first.id : null);

          if (activeMatchId == null) {
            return const _LeaderboardMessage(
              message: 'Leaderboard will appear once live or completed matches are available.',
            );
          }

          final leaderboardAsync = ref.watch(leaderboardStreamProvider(activeMatchId));

          return Column(
            children: [
              if (availableMatches.isNotEmpty)
                SizedBox(
                  height: 54,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final match in availableMatches)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${match.teamA} vs ${match.teamB}'),
                            selected: activeMatchId == match.id,
                            onSelected: (_) => setState(() => _selectedMatchId = match.id),
                            selectedColor: AppColors.primaryAccent,
                            labelStyle: TextStyle(
                              color: activeMatchId == match.id
                                  ? AppColors.background
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: leaderboardAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const _LeaderboardMessage(
                        message: 'No contest entries have been scored for this match yet.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final isTopThree = entry.rank <= 3;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isTopThree ? _medalColor(entry.rank) : AppColors.secondaryCard,
                              width: isTopThree ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _medalColor(entry.rank).withValues(alpha: 0.2),
                                child: entry.rank <= 3
                                    ? Icon(
                                        Icons.emoji_events,
                                        color: _medalColor(entry.rank),
                                      )
                                    : Text(
                                        '#${entry.rank}',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.username,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Captain: ${entry.captainName}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${entry.totalPoints} pts',
                                style: const TextStyle(
                                  color: AppColors.primaryAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _LeaderboardMessage(
                    message: 'Unable to load leaderboard.\n$error',
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LeaderboardMessage(
          message: 'Unable to load matches for leaderboard selection.\n$error',
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? const BottomNavBar(currentIndex: 3) : null,
    );
  }

  Color _medalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textSecondary;
    }
  }
}

class _LeaderboardMessage extends StatelessWidget {
  const _LeaderboardMessage({required this.message});

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

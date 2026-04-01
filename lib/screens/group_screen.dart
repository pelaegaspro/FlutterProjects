import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.effectiveDisplayName ?? 'Captain';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text(
            'Group Hub',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.primaryAccent,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Chat'),
              Tab(text: 'Leaderboard'),
              Tab(text: 'Matches'),
            ],
          ),
        ),
        body: Column(
          children: [
            _GroupHeader(displayName: displayName),
            Expanded(
              child: TabBarView(
                children: [
                  _GroupChatTab(displayName: displayName),
                  _GroupLeaderboardTab(displayName: displayName),
                  const _GroupMatchesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondaryCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'PRIVATE GROUP',
                  style: TextStyle(
                    color: AppColors.primaryAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.groups_2, color: AppColors.textPrimary),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Weekend Warriors',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$displayName, this is your friends-only fantasy room. Chat, track rankings, and jump into matches together.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _GroupStatChip(icon: Icons.people_alt_outlined, label: '8 members'),
              SizedBox(width: 10),
              _GroupStatChip(icon: Icons.vpn_key_outlined, label: 'Code WAR-XI'),
              SizedBox(width: 10),
              _GroupStatChip(icon: Icons.emoji_events_outlined, label: '3 active battles'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupStatChip extends StatelessWidget {
  const _GroupStatChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondaryCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupChatTab extends StatelessWidget {
  const _GroupChatTab({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final messages = <_GroupMessage>[
      const _GroupMessage(
        sender: 'Riya',
        text: 'I am backing the spinners today. Don\'t copy my differential picks.',
        time: '7:42 PM',
      ),
      const _GroupMessage(
        sender: 'Arjun',
        text: 'Too late. I already stole your vice-captain idea.',
        time: '7:44 PM',
      ),
      _GroupMessage(
        sender: displayName,
        text: 'I just need one safe opener and one chaos pick. That is the whole strategy.',
        time: '7:47 PM',
        isCurrentUser: true,
      ),
      const _GroupMessage(
        sender: 'Neha',
        text: 'Once realtime is wired, this is where live banter and toss updates will land.',
        time: '7:49 PM',
      ),
    ];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.bolt, color: AppColors.primaryAccent, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Phase 1 UI is ready here. Next step is wiring Supabase Realtime messages for this group.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Align(
                alignment: message.isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: message.isCurrentUser ? AppColors.primaryAccent : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: message.isCurrentUser
                        ? null
                        : Border.all(color: AppColors.secondaryCard),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.sender,
                        style: TextStyle(
                          color: message.isCurrentUser ? AppColors.background : AppColors.primaryAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isCurrentUser ? AppColors.background : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message.time,
                        style: TextStyle(
                          color: message.isCurrentUser
                              ? AppColors.background.withValues(alpha: 0.8)
                              : AppColors.textSecondary,
                          fontSize: 11,
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.secondaryCard)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Realtime chat composer comes in the next step',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.send, color: AppColors.background),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupLeaderboardTab extends StatelessWidget {
  const _GroupLeaderboardTab({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final standings = <_GroupStanding>[
      const _GroupStanding(name: 'Riya', points: 842, change: '+31', rank: 1),
      const _GroupStanding(name: 'Arjun', points: 815, change: '+14', rank: 2),
      _GroupStanding(name: displayName, points: 798, change: '+26', rank: 3, isCurrentUser: true),
      const _GroupStanding(name: 'Neha', points: 760, change: '-8', rank: 4),
      const _GroupStanding(name: 'Sam', points: 734, change: '+11', rank: 5),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const Text(
          'Private Group Ranking',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'This is the direction for group-only competition. Next, we will back it with actual group membership and fantasy points.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        ...standings.map(
          (entry) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: entry.isCurrentUser ? AppColors.primaryAccent.withValues(alpha: 0.12) : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: entry.isCurrentUser ? AppColors.primaryAccent : AppColors.secondaryCard,
                width: entry.isCurrentUser ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _rankColor(entry.rank).withValues(alpha: 0.18),
                  child: Text(
                    '#${entry.rank}',
                    style: TextStyle(
                      color: _rankColor(entry.rank),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.isCurrentUser ? 'You are in podium range.' : 'Locked into today\'s private contest.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.points} pts',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.change,
                      style: TextStyle(
                        color: entry.change.startsWith('-') ? const Color(0xFFF87171) : AppColors.primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF59E0B);
      case 2:
        return AppColors.silver;
      case 3:
        return const Color(0xFFF97316);
      default:
        return AppColors.textSecondary;
    }
  }
}

class _GroupMatchesTab extends ConsumerWidget {
  const _GroupMatchesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(allMatchesProvider);

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No matches are available yet for your group.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final visibleMatches = matches.take(5).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            const Text(
              'Play Together',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use this section to decide which real-world match the group is targeting today.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ...visibleMatches.map(
              (match) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondaryCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusBadge(status: match.status),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM, hh:mm a').format(match.scheduledTime),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${match.teamA} vs ${match.teamB}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.venue,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (match.scoreA != null || match.scoreB != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${match.teamA}: ${match.scoreA ?? '-'}   |   ${match.teamB}: ${match.scoreB ?? '-'}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/join-match'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: AppColors.background,
                        ),
                        child: const Text('Open Join Match'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to load group matches.\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'LIVE' => AppColors.liveBadge,
      'COMPLETED' => AppColors.completedBadge,
      _ => AppColors.upcomingBadge,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GroupMessage {
  const _GroupMessage({
    required this.sender,
    required this.text,
    required this.time,
    this.isCurrentUser = false,
  });

  final String sender;
  final String text;
  final String time;
  final bool isCurrentUser;
}

class _GroupStanding {
  const _GroupStanding({
    required this.name,
    required this.points,
    required this.change,
    required this.rank,
    this.isCurrentUser = false,
  });

  final String name;
  final int points;
  final String change;
  final int rank;
  final bool isCurrentUser;
}

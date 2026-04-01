import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/match_provider.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
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
        actions: [
          IconButton(
            onPressed: user == null
                ? null
                : () => _showJoinGroupDialog(
                      context: context,
                      ref: ref,
                    ),
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Join group',
          ),
          IconButton(
            onPressed: user == null
                ? null
                : () => _showCreateGroupDialog(
                      context: context,
                      ref: ref,
                      userId: user.id,
                    ),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create group',
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (user == null) {
            return const _GroupInfoState(
              title: 'Sign in to unlock groups',
              message: 'Your private fantasy groups, live chat, and group rankings will appear here after login.',
            );
          }

          if (groups.isEmpty) {
            return _EmptyGroupState(
              onJoin: () => _showJoinGroupDialog(
                context: context,
                ref: ref,
              ),
              onCreate: () => _showCreateGroupDialog(
                context: context,
                ref: ref,
                userId: user.id,
              ),
            );
          }

          final currentGroup = ref.watch(currentGroupProvider) ?? groups.first;

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                _GroupHeader(
                  group: currentGroup,
                  displayName: user.effectiveDisplayName,
                ),
                _GroupSelector(
                  groups: groups,
                  activeGroupId: currentGroup.id,
                  onSelected: (groupId) {
                    ref.read(selectedGroupIdProvider.notifier).state = groupId;
                  },
                ),
                const Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        indicatorColor: AppColors.primaryAccent,
                        labelColor: AppColors.textPrimary,
                        unselectedLabelColor: AppColors.textSecondary,
                        tabs: [
                          Tab(text: 'Chat'),
                          Tab(text: 'Leaderboard'),
                          Tab(text: 'Matches'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _GroupChatTab(),
                            _GroupLeaderboardTab(),
                            _GroupMatchesTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _GroupInfoState(
          title: 'Unable to load groups',
          message: '$error',
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
  }) async {
    final controller = TextEditingController();
    try {
      final groupName = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Create Group',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Weekend Warriors',
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(controller.text),
                child: const Text('Create'),
              ),
            ],
          );
        },
      );

      if (groupName == null || groupName.trim().isEmpty) {
        return;
      }

      final service = ref.read(groupServiceProvider);
      final groupId = await service.createGroup(name: groupName, userId: userId);
      ref.read(selectedGroupIdProvider.notifier).state = groupId;
      ref.invalidate(userGroupsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create group: $error')),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showJoinGroupDialog({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final controller = TextEditingController();
    try {
      final inviteCode = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Join Group',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'AB12CD34',
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(controller.text),
                child: const Text('Join'),
              ),
            ],
          );
        },
      );

      if (inviteCode == null || inviteCode.trim().isEmpty) {
        return;
      }

      final groupId = await ref.read(groupServiceProvider).joinGroup(
            inviteCode: inviteCode,
          );

      ref.read(selectedGroupIdProvider.notifier).state = groupId;
      ref.invalidate(userGroupsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined group successfully.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to join group: $error')),
        );
      }
    } finally {
      controller.dispose();
    }
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.displayName,
  });

  final FantasyGroup group;
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
          Text(
            group.name,
            style: const TextStyle(
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
          Row(
            children: [
              _GroupStatChip(
                icon: Icons.people_alt_outlined,
                label: '${group.memberCount} members',
              ),
              const SizedBox(width: 10),
              _GroupStatChip(
                icon: Icons.vpn_key_outlined,
                label: 'Code ${group.inviteCode}',
              ),
              const SizedBox(width: 10),
              _GroupStatChip(
                icon: Icons.schedule_outlined,
                label: group.createdAt == null
                    ? 'Created now'
                    : DateFormat('dd MMM').format(group.createdAt!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupSelector extends StatelessWidget {
  const _GroupSelector({
    required this.groups,
    required this.activeGroupId,
    required this.onSelected,
  });

  final List<FantasyGroup> groups;
  final String activeGroupId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final group in groups)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(group.name),
                selected: group.id == activeGroupId,
                onSelected: (_) => onSelected(group.id),
                selectedColor: AppColors.primaryAccent,
                labelStyle: TextStyle(
                  color: group.id == activeGroupId ? AppColors.background : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

class _GroupChatTab extends ConsumerStatefulWidget {
  const _GroupChatTab();

  @override
  ConsumerState<_GroupChatTab> createState() => _GroupChatTabState();
}

class _GroupChatTabState extends ConsumerState<_GroupChatTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final group = ref.watch(currentGroupProvider);
    final messagesAsync = ref.watch(currentGroupMessagesProvider);

    if (group == null || user == null) {
      return const _GroupInfoState(
        title: 'No group selected',
        message: 'Choose or create a group to start chatting.',
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.2)),
          ),
          child: Text(
            'Live chat is connected for ${group.name}. New messages stream automatically through Supabase Realtime.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              _scrollToBottom();

              if (messages.isEmpty) {
                return const _GroupInfoState(
                  title: 'No messages yet',
                  message: 'Start the first conversation for this group.',
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message.userId == user.id;
                  return _MessageBubble(
                    message: message,
                    isCurrentUser: isCurrentUser,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _GroupInfoState(
              title: 'Unable to load chat',
              message: '$error',
            ),
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
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: AppColors.textPrimary),
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Message your group',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _sendMessage(group.id, user.id),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.send, color: AppColors.background),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage(String groupId, String userId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    try {
      await ref.read(chatServiceProvider).sendMessage(
            groupId: groupId,
            userId: userId,
            text: text,
          );
      _controller.clear();
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to send message: $error')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
  });

  final GroupChatMessage message;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isCurrentUser ? AppColors.primaryAccent : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: isCurrentUser ? null : Border.all(color: AppColors.secondaryCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentUser ? 'You' : message.senderLabel,
              style: TextStyle(
                color: isCurrentUser ? AppColors.background : AppColors.primaryAccent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.message,
              style: TextStyle(
                color: isCurrentUser ? AppColors.background : AppColors.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('hh:mm a').format(message.createdAt),
              style: TextStyle(
                color: isCurrentUser
                    ? AppColors.background.withValues(alpha: 0.8)
                    : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLeaderboardTab extends ConsumerWidget {
  const _GroupLeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(currentGroupLeaderboardProvider);
    final user = ref.watch(currentUserProvider);
    final group = ref.watch(currentGroupProvider);

    if (group == null) {
      return const _GroupInfoState(
        title: 'No group selected',
        message: 'Choose a group to see its private leaderboard.',
      );
    }

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const _GroupInfoState(
            title: 'No leaderboard data yet',
            message: 'Group rankings will appear here once points are written into Supabase.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Text(
              '${group.name} Ranking',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This leaderboard is sorted live from group_leaderboard by points.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            ...entries.map(
              (entry) => _LeaderboardRow(
                entry: entry,
                isCurrentUser: entry.userId == user?.id,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _GroupInfoState(
        title: 'Unable to load leaderboard',
        message: '$error',
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.isCurrentUser,
  });

  final GroupLeaderboardEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primaryAccent.withValues(alpha: 0.12) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? AppColors.primaryAccent : AppColors.secondaryCard,
          width: isCurrentUser ? 1.4 : 1,
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
                  isCurrentUser ? 'You' : entry.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCurrentUser ? 'Current standing in your group' : 'Private group competitor',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.points} pts',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
    final group = ref.watch(currentGroupProvider);

    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return const _GroupInfoState(
            title: 'No matches available',
            message: 'There are no fantasy matches available for your group right now.',
          );
        }

        final visibleMatches = matches.take(5).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Text(
              group == null ? 'Play Together' : '${group.name} Match Room',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The group filter hook is ready. This tab still uses the current shared match feed until per-group match targeting is added.',
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
      error: (error, _) => _GroupInfoState(
        title: 'Unable to load matches',
        message: '$error',
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

class _EmptyGroupState extends StatelessWidget {
  const _EmptyGroupState({
    required this.onCreate,
    required this.onJoin,
  });

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.groups_2_outlined,
              color: AppColors.primaryAccent,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Create your first private group',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Once a group exists, chat, leaderboard, and group match coordination will all come alive here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.background,
              ),
              child: const Text('Create Group'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onJoin,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.secondaryCard),
              ),
              child: const Text('Join with Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupInfoState extends StatelessWidget {
  const _GroupInfoState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

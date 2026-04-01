import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../providers/auth_providers.dart';
import '../providers/fantasy_providers.dart';
import '../widgets/match_tile.dart';
import 'match_workspace_screen.dart';

class MatchListScreen extends ConsumerWidget {
  const MatchListScreen({
    super.key,
    required this.userName,
  });

  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final authService = ref.watch(authServiceProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(matchesProvider);
        await ref.read(matchesProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi $userName',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Generate, batch, copy, and recreate teams fast.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => authService.signOut(),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                runSpacing: 16,
                spacing: 16,
                children: const [
                  _StatChip(title: 'Generator', value: '10 to 100 teams'),
                  _StatChip(title: 'Batch Flow', value: '20 teams per page'),
                  _StatChip(title: 'Captain Logic', value: 'Top-5 rotation'),
                  _StatChip(title: 'Copy Speed', value: 'Single or batch export'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          matchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) {
                return const _StateCard(
                  title: 'No matches available',
                  body: 'Add documents to the Firestore `matches` collection or use the seeded demo records.',
                );
              }

              return Column(
                children: matches.map((match) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MatchTile(
                      match: match,
                      subtitle: DateFormat('EEE, d MMM • hh:mm a').format(match.startTime),
                      onGenerateTeams: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MatchWorkspaceScreen(match: match),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const _StateCard(
              title: 'Loading matches',
              body: 'Fetching match cards from Firestore or demo storage.',
              loading: true,
            ),
            error: (error, _) => _StateCard(
              title: 'Unable to load matches',
              body: error.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.body,
    this.loading = false,
  });

  final String title;
  final String body;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
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

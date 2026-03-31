import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_config.dart';
import '../core/theme.dart';
import '../providers/match_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/match_card.dart';
import '../widgets/shimmer_loader.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = switch (_selectedTab) {
      0 => ref.watch(liveMatchesProvider),
      1 => ref.watch(upcomingMatchesProvider),
      _ => ref.watch(completedMatchesProvider),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Matches',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.background,
            child: TabBar(
              controller: _tabController,
              onTap: (index) => setState(() => _selectedTab = index),
              labelColor: AppColors.primaryAccent,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryAccent,
              tabs: const [
                Tab(text: 'Live'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(liveMatchesProvider);
                ref.invalidate(upcomingMatchesProvider);
                ref.invalidate(completedMatchesProvider);
                ref.invalidate(allMatchesProvider);
                await ref.read(allMatchesProvider.future);
              },
              child: matchesAsync.when(
                data: (matches) {
                  if (!AppConfig.hasCricApiConfig &&
                      !AppConfig.hasPremiumFeedConfig &&
                      matches.isEmpty) {
                    return _StateListView(
                      message: 'Add cricket data configuration to load live matches for this build.',
                    );
                  }

                  if (matches.isEmpty) {
                    return const _StateListView(
                      message: 'No matches available right now. Pull to refresh and try again.',
                    );
                  }

                  return ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return MatchCard(
                        match: match,
                        ctaLabel: match.isCompleted ? 'Completed' : 'Create Team',
                        onCreateTeam: match.isCompleted
                            ? null
                            : () => context.push('/player-selection/${match.id}'),
                      );
                    },
                  );
                },
                loading: () => const ShimmerLoader(itemCount: 4, height: 170),
                error: (error, _) => _StateListView(
                  message: 'Unable to load matches.\n$error',
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

class _StateListView extends StatelessWidget {
  const _StateListView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
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
          ),
        ),
      ],
    );
  }
}

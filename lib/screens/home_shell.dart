import 'package:flutter/material.dart';

import '../widgets/bottom_nav.dart';
import 'contests_screen.dart';
import 'leaderboard_screen.dart';
import 'matches_screen.dart';
import 'my_teams_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.initialIndex = 0,
    this.leaderboardMatchId,
  });

  final int initialIndex;
  final String? leaderboardMatchId;

  static const List<String> tabKeys = <String>[
    'matches',
    'contests',
    'my-teams',
    'leaderboard',
    'profile',
  ];

  static int indexFromTab(String? tab) {
    final index = tabKeys.indexOf(tab ?? '');
    return index >= 0 ? index : 0;
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex && widget.initialIndex != _currentIndex) {
      _currentIndex = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const MatchesScreen(showBottomNav: false),
      const ContestsScreen(showBottomNav: false),
      const MyTeamsScreen(showBottomNav: false),
      LeaderboardScreen(
        matchId: widget.leaderboardMatchId,
        showBottomNav: false,
      ),
      const ProfileScreen(showBottomNav: false),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

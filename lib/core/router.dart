import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/captain_screen.dart';
import '../screens/home_shell.dart';
import '../screens/login_screen.dart';
import '../screens/player_selection_screen.dart';
import '../screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  final refresh = _GoRouterRefreshStream(supabase.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final isLoggedIn = supabase.isLoggedIn();
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/splash';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && location == '/login') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => HomeShell(
          initialIndex: HomeShell.indexFromTab(state.uri.queryParameters['tab']),
          leaderboardMatchId: state.uri.queryParameters['matchId'],
        ),
      ),
      GoRoute(
        path: '/matches',
        redirect: (context, state) => '/home?tab=matches',
      ),
      GoRoute(
        path: '/player-selection/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return PlayerSelectionScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/captain-selection/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return CaptainScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/my-teams',
        redirect: (context, state) => '/home?tab=my-teams',
      ),
      GoRoute(
        path: '/contests',
        redirect: (context, state) => '/home?tab=contests',
      ),
      GoRoute(
        path: '/leaderboard',
        redirect: (context, state) {
          final matchId = state.uri.queryParameters['matchId'];
          if (matchId == null || matchId.isEmpty) {
            return '/home?tab=leaderboard';
          }
          final encodedMatchId = Uri.encodeQueryComponent(matchId);
          return '/home?tab=leaderboard&matchId=$encodedMatchId';
        },
      ),
      GoRoute(
        path: '/profile',
        redirect: (context, state) => '/home?tab=profile',
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

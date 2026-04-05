import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/captain_screen.dart';
import '../screens/contests_screen.dart';
import '../screens/group_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/matches_screen.dart';
import '../screens/my_teams_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/player_selection_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  final refresh = _GoRouterRefreshStream(auth.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn();
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/otp' || location == '/splash';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
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
        path: '/otp',
        builder: (context, state) => OtpScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
        ),
      ),
      GoRoute(
        path: '/home',
        redirect: (context, state) => '/matches',
      ),
      GoRoute(
        path: '/matches',
        builder: (context, state) => const MatchesScreen(),
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
        builder: (context, state) => const MyTeamsScreen(),
      ),
      GoRoute(
        path: '/contests',
        builder: (context, state) => const ContestsScreen(),
      ),
      GoRoute(
        path: '/group',
        builder: (context, state) => const GroupScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) {
          final matchId = state.uri.queryParameters['matchId'];
          return LeaderboardScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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

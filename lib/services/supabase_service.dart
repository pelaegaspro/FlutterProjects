import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sp;

import '../models/models.dart';

class SupabaseService {
  final sp.SupabaseClient _supabase = sp.Supabase.instance.client;

  Stream<User?> authStateChanges() {
    return _supabase.auth.onAuthStateChange
        .map((authState) => _mapAuthUser(authState.session?.user ?? _supabase.auth.currentUser))
        .startWith(_mapAuthUser(_supabase.auth.currentUser));
  }

  User? getCurrentUser() => _mapAuthUser(_supabase.auth.currentUser);

  bool isLoggedIn() => _supabase.auth.currentUser != null;

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<List<Team>> getUserTeams(String userId) async {
    final response = await _supabase
        .from('teams')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .whereType<Map>()
        .map((item) => Team.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Team?> getTeamById(String teamId) async {
    final response = await _supabase.from('teams').select().eq('id', teamId).maybeSingle();
    if (response == null) {
      return null;
    }
    return Team.fromJson((response as Map).cast<String, dynamic>());
  }

  Future<String> createTeam(Team team) async {
    final response = await _supabase
        .from('teams')
        .insert({
          'user_id': team.userId,
          'match_id': team.matchId,
          'team_name': team.teamName,
          'players': team.players.map((player) => player.toJson()).toList(),
          'captain_id': team.captainId,
          'vice_captain_id': team.viceCaptainId,
          'total_credits': team.totalCredits,
        })
        .select()
        .single();

    return response['id'].toString();
  }

  Future<List<Contest>> getContests({String? matchId}) async {
    dynamic query = _supabase.from('contests').select().order('created_at');
    if (matchId != null && matchId.isNotEmpty) {
      query = query.eq('match_id', matchId);
    }
    final response = await query;
    return (response as List)
        .whereType<Map>()
        .map((item) => Contest.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> joinContest({
    required String contestId,
    required String teamId,
    required String userId,
  }) async {
    await _supabase.from('contest_entries').insert({
      'contest_id': contestId,
      'team_id': teamId,
      'user_id': userId,
    });
  }

  Future<int> getJoinedContestCount(String userId) async {
    try {
      final response = await _supabase
          .from('contest_entries')
          .select('id', const sp.FetchOptions(count: sp.CountOption.exact, head: true))
          .eq('user_id', userId);
      return response.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<LeaderboardEntry>> getLeaderboard(String matchId) async {
    final response = await _supabase
        .from('leaderboard')
        .select()
        .eq('match_id', matchId)
        .order('total_points', ascending: false);

    final rows = (response as List)
        .whereType<Map>()
        .map((item) => LeaderboardEntry.fromJson(item.cast<String, dynamic>()))
        .toList();

    return _rankEntries(rows);
  }

  Stream<List<LeaderboardEntry>> watchLeaderboard(String matchId) {
    return _supabase
        .from('leaderboard')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .map(
          (rows) => rows
              .map((row) => LeaderboardEntry.fromJson(row))
              .toList(),
        )
        .map(_rankEntries);
  }

  User? _mapAuthUser(sp.User? user) {
    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata ?? const {};
    return User(
      id: user.id,
      email: user.email ?? '',
      displayName: metadata['display_name']?.toString() ?? metadata['name']?.toString(),
    );
  }

  List<LeaderboardEntry> _rankEntries(List<LeaderboardEntry> entries) {
    final sorted = [...entries]..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return [
      for (var index = 0; index < sorted.length; index++)
        LeaderboardEntry(
          id: sorted[index].id,
          userId: sorted[index].userId,
          matchId: sorted[index].matchId,
          teamId: sorted[index].teamId,
          totalPoints: sorted[index].totalPoints,
          rank: index + 1,
          username: sorted[index].username.isEmpty ? 'Player ${index + 1}' : sorted[index].username,
          captainName: sorted[index].captainName,
          updatedAt: sorted[index].updatedAt,
        ),
    ];
  }
}

extension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}

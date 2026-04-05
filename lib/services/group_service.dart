import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group.dart';
import 'supabase_client.dart';

class GroupService {
  Future<List<FantasyGroup>> getUserGroups(String userId) async {
    try {
      final memberships = await supabaseClient
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (memberships as List)
          .whereType<Map>()
          .map((row) => row['group_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (groupIds.isEmpty) {
        return const [];
      }

      final groupsResponse = await supabaseClient
          .from('groups')
          .select()
          .inFilter('id', groupIds)
          .order('created_at');

      final memberRows = await supabaseClient
          .from('group_members')
          .select('group_id')
          .inFilter('group_id', groupIds);

      final memberCounts = <String, int>{};
      for (final row in (memberRows as List).whereType<Map>()) {
        final groupId = row['group_id']?.toString();
        if (groupId == null || groupId.isEmpty) {
          continue;
        }
        memberCounts[groupId] = (memberCounts[groupId] ?? 0) + 1;
      }

      return (groupsResponse as List)
          .whereType<Map>()
          .map(
            (row) => FantasyGroup.fromJson({
              ...row.cast<String, dynamic>(),
              'member_count': memberCounts[row['id']?.toString() ?? ''] ?? 0,
            }),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw _friendlyError(error);
    }
  }

  Future<String> createGroup({
    required String name,
    required String userId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Group name cannot be empty.');
    }

    try {
      final response = await _insertGroupWithInviteCode(
        name: trimmedName,
        userId: userId,
      );

      final groupId = response['id'].toString();

      await supabaseClient.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
      });

      await _ensureLeaderboardEntry(
        groupId: groupId,
        userId: userId,
      );

      return groupId;
    } on PostgrestException catch (error) {
      throw _friendlyError(error);
    }
  }

  Future<String> joinGroup({
    required String inviteCode,
  }) async {
    final normalizedInviteCode = _normalizeInviteCode(inviteCode);
    if (normalizedInviteCode.isEmpty) {
      throw Exception('Invite code cannot be empty.');
    }

    try {
      final response = await supabaseClient.rpc(
        'join_group_by_invite',
        params: {'target_invite_code': normalizedInviteCode},
      );

      final groupId = response?.toString() ?? '';
      if (groupId.isEmpty) {
        throw Exception('Unable to join group.');
      }

      return groupId;
    } on PostgrestException catch (error) {
      throw _friendlyError(error);
    }
  }

  Stream<List<GroupLeaderboardEntry>> watchGroupLeaderboard(String groupId) {
    return supabaseClient
        .from('group_leaderboard')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .map(
          (rows) => rows
              .map((row) => GroupLeaderboardEntry.fromJson(row))
              .toList()
            ..sort((a, b) => b.points.compareTo(a.points)),
        )
        .map(_applyRanks);
  }

  List<GroupLeaderboardEntry> _applyRanks(List<GroupLeaderboardEntry> entries) {
    final ranked = <GroupLeaderboardEntry>[];

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      ranked.add(
        GroupLeaderboardEntry(
          id: entry.id,
          groupId: entry.groupId,
          userId: entry.userId,
          points: entry.points,
          rank: index + 1,
        ),
      );
    }

    return ranked;
  }

  Future<void> _ensureLeaderboardEntry({
    required String groupId,
    required String userId,
  }) {
    return supabaseClient.from('group_leaderboard').upsert(
      {
        'group_id': groupId,
        'user_id': userId,
        'points': 0,
      },
      onConflict: 'group_id,user_id',
    );
  }

  Future<Map<String, dynamic>> _insertGroupWithInviteCode({
    required String name,
    required String userId,
  }) async {
    PostgrestException? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      final inviteCode = _generateInviteCode();

      try {
        final response = await supabaseClient
            .from('groups')
            .insert({
              'name': name,
              'created_by': userId,
              'invite_code': inviteCode,
            })
            .select()
            .single();

        return response;
      } on PostgrestException catch (error) {
        lastError = error;
        if (!_isInviteCodeConflict(error) || attempt == 2) {
          rethrow;
        }
      }
    }

    throw lastError ?? Exception('Unable to create group.');
  }

  bool _isInviteCodeConflict(PostgrestException error) {
    final details = error.details?.toString() ?? '';
    return error.code == '23505' &&
        (error.message.contains('invite_code') ||
            details.contains('invite_code'));
  }

  String _generateInviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  String _normalizeInviteCode(String inviteCode) {
    return inviteCode.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  Exception _friendlyError(PostgrestException error) {
    if (error.code == 'PGRST205') {
      return Exception(
        'Groups are not set up in Supabase yet. Run supabase_group_schema.sql in your Supabase SQL editor.',
      );
    }

    return Exception(error.message);
  }
}

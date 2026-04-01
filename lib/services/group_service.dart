import '../models/group.dart';
import 'supabase_client.dart';

class GroupService {
  Future<List<FantasyGroup>> getUserGroups(String userId) async {
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
  }

  Future<String> createGroup({
    required String name,
    required String userId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Group name cannot be empty.');
    }

    final response = await supabaseClient
        .from('groups')
        .insert({
          'name': trimmedName,
          'created_by': userId,
        })
        .select()
        .single();

    final groupId = response['id'].toString();

    await supabaseClient.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
    });

    return groupId;
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

  Future<List<GroupLeaderboardEntry>> getGroupLeaderboard(String groupId) async {
    final response = await supabaseClient
        .from('group_leaderboard')
        .select()
        .eq('group_id', groupId)
        .order('points', ascending: false);

    final entries = (response as List)
        .whereType<Map>()
        .map((row) => GroupLeaderboardEntry.fromJson(row.cast<String, dynamic>()))
        .toList();

    return _applyRanks(entries);
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
}

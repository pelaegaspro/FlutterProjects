import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/group.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/group_service.dart';
import 'auth_provider.dart';

final groupServiceProvider = Provider<GroupService>((ref) => GroupService());
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final selectedGroupIdProvider = StateProvider<String?>((ref) => null);

final userGroupsProvider = FutureProvider<List<FantasyGroup>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const [];
  }

  final service = ref.watch(groupServiceProvider);
  return service.getUserGroups(user.id);
});

final currentGroupProvider = Provider<FantasyGroup?>((ref) {
  final groups = ref.watch(userGroupsProvider).maybeWhen(
        data: (value) => value,
        orElse: () => const <FantasyGroup>[],
      );
  if (groups.isEmpty) {
    return null;
  }

  final selectedGroupId = ref.watch(selectedGroupIdProvider);
  if (selectedGroupId == null) {
    return groups.first;
  }

  for (final group in groups) {
    if (group.id == selectedGroupId) {
      return group;
    }
  }

  return groups.first;
});

final currentGroupMessagesProvider = StreamProvider<List<GroupChatMessage>>((ref) {
  final group = ref.watch(currentGroupProvider);
  if (group == null) {
    return Stream.value(const <GroupChatMessage>[]);
  }

  final service = ref.watch(chatServiceProvider);
  return service.watchMessages(group.id);
});

final currentGroupLeaderboardProvider = StreamProvider<List<GroupLeaderboardEntry>>((ref) {
  final group = ref.watch(currentGroupProvider);
  if (group == null) {
    return Stream.value(const <GroupLeaderboardEntry>[]);
  }

  final service = ref.watch(groupServiceProvider);
  return service.watchGroupLeaderboard(group.id);
});

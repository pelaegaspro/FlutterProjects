import '../models/message.dart';
import 'supabase_client.dart';

class ChatService {
  Stream<List<GroupChatMessage>> watchMessages(String groupId) {
    return supabaseClient
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at')
        .map(
          (rows) => rows
              .map((row) => GroupChatMessage.fromJson(row))
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        );
  }

  Future<void> sendMessage({
    required String groupId,
    required String userId,
    required String text,
  }) async {
    final message = text.trim();
    if (message.isEmpty) {
      return;
    }

    await supabaseClient.from('messages').insert({
      'group_id': groupId,
      'user_id': userId,
      'message': message,
    });
  }
}

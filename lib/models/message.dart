class GroupChatMessage {
  const GroupChatMessage({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String userId;
  final String message;
  final DateTime createdAt;

  String get senderLabel {
    if (userId.length <= 8) {
      return userId;
    }
    return 'Member ${userId.substring(0, 6)}';
  }

  factory GroupChatMessage.fromJson(Map<String, dynamic> json) {
    return GroupChatMessage(
      id: _stringValue(json['id']),
      groupId: _stringValue(
        json['group_id'],
        fallback: _stringValue(json['groupId']),
      ),
      userId: _stringValue(
        json['user_id'],
        fallback: _stringValue(json['userId']),
      ),
      message: _stringValue(json['message']),
      createdAt: _dateTimeValue(json['created_at']) ??
          _dateTimeValue(json['createdAt']) ??
          DateTime.now(),
    );
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

DateTime? _dateTimeValue(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}

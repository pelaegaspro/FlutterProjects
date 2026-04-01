class FantasyGroup {
  const FantasyGroup({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String createdBy;
  final DateTime? createdAt;
  final int memberCount;

  String get inviteCode {
    final compact = id.replaceAll('-', '').toUpperCase();
    return compact.length >= 8 ? compact.substring(0, 8) : compact;
  }

  factory FantasyGroup.fromJson(Map<String, dynamic> json) {
    return FantasyGroup(
      id: _stringValue(json['id']),
      name: _stringValue(json['name'], fallback: 'My Group'),
      createdBy: _stringValue(json['created_by'], fallback: _stringValue(json['createdBy'])),
      createdAt: _dateTimeValue(json['created_at']) ?? _dateTimeValue(json['createdAt']),
      memberCount: _intValue(json['member_count'], fallback: _intValue(json['memberCount'])),
    );
  }
}

class GroupLeaderboardEntry {
  const GroupLeaderboardEntry({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.points,
    required this.rank,
  });

  final String id;
  final String groupId;
  final String userId;
  final int points;
  final int rank;

  String get displayName {
    if (userId.length <= 8) {
      return userId;
    }
    return 'Player ${userId.substring(0, 6)}';
  }

  factory GroupLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return GroupLeaderboardEntry(
      id: _stringValue(json['id']),
      groupId: _stringValue(json['group_id'], fallback: _stringValue(json['groupId'])),
      userId: _stringValue(json['user_id'], fallback: _stringValue(json['userId'])),
      points: _intValue(json['points']),
      rank: _intValue(json['rank']),
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

int _intValue(dynamic value, {int fallback = 0}) {
  if (value == null) {
    return fallback;
  }
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.tryParse(value.toString()) ?? fallback;
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

class User {
  final String id;
  final String email;
  final String? displayName;

  const User({
    required this.id,
    required this.email,
    this.displayName,
  });

  String get effectiveDisplayName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }

    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'Player';
  }
}

class Match {
  final String id;
  final String teamA;
  final String teamB;
  final String status;
  final String venue;
  final DateTime scheduledTime;
  final String? scoreA;
  final String? scoreB;

  const Match({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.status,
    required this.venue,
    required this.scheduledTime,
    this.scoreA,
    this.scoreB,
  });

  bool get isLive => status == 'LIVE';
  bool get isUpcoming => status == 'UPCOMING';
  bool get isCompleted => status == 'COMPLETED';

  Match copyWith({
    String? id,
    String? teamA,
    String? teamB,
    String? status,
    String? venue,
    DateTime? scheduledTime,
    String? scoreA,
    String? scoreB,
  }) {
    return Match(
      id: id ?? this.id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      status: status ?? this.status,
      venue: venue ?? this.venue,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
    );
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: _stringValue(json['id'], fallback: _stringValue(json['match_id'], fallback: '')),
      teamA: _stringValue(json['teamA'], fallback: _stringValue(json['team_a'], fallback: 'Team A')),
      teamB: _stringValue(json['teamB'], fallback: _stringValue(json['team_b'], fallback: 'Team B')),
      status: _normalizeMatchStatus(_stringValue(json['status'], fallback: 'UPCOMING')),
      venue: _stringValue(json['venue'], fallback: 'Venue pending'),
      scheduledTime: _dateTimeValue(json['scheduledTime']) ??
          _dateTimeValue(json['scheduled_time']) ??
          DateTime.now(),
      scoreA: _nullableStringValue(json['scoreA'] ?? json['score_a']),
      scoreB: _nullableStringValue(json['scoreB'] ?? json['score_b']),
    );
  }

  factory Match.fromCricApi(Map<String, dynamic> json) {
    final teamInfo = _listOfMaps(json['teamInfo']);
    final teams = _listOfStrings(json['teams']);
    final scorecards = _listOfMaps(json['score']);

    final teamA = teamInfo.isNotEmpty
        ? _stringValue(teamInfo.first['name'], fallback: teams.isNotEmpty ? teams.first : 'Team A')
        : (teams.isNotEmpty ? teams.first : 'Team A');
    final teamB = teamInfo.length > 1
        ? _stringValue(teamInfo[1]['name'], fallback: teams.length > 1 ? teams[1] : 'Team B')
        : (teams.length > 1 ? teams[1] : 'Team B');

    String? inningToScore(Map<String, dynamic> inning) {
      final runs = inning['r'];
      final wickets = inning['w'];
      if (runs == null) {
        return null;
      }
      final score = wickets == null ? '$runs' : '$runs/$wickets';
      final overs = inning['o'];
      if (overs == null) {
        return score;
      }
      return '$score ($overs ov)';
    }

    return Match(
      id: _stringValue(json['id'], fallback: _stringValue(json['matchId'], fallback: '')),
      teamA: teamA,
      teamB: teamB,
      status: _normalizeMatchStatus(_stringValue(json['status'], fallback: 'UPCOMING')),
      venue: _stringValue(json['venue'], fallback: 'Venue pending'),
      scheduledTime: _dateTimeValue(json['dateTimeGMT']) ??
          _dateTimeValue(json['date']) ??
          _dateTimeValue(json['dateTime']) ??
          DateTime.now(),
      scoreA: scorecards.isNotEmpty ? inningToScore(scorecards.first) : null,
      scoreB: scorecards.length > 1 ? inningToScore(scorecards[1]) : null,
    );
  }
}

class Player {
  final String id;
  final String name;
  final String team;
  final String role;
  final int credits;
  final double? selectedPercentage;
  final int? points;

  const Player({
    required this.id,
    required this.name,
    required this.team,
    required this.role,
    required this.credits,
    this.selectedPercentage,
    this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'team': team,
        'role': role,
        'credits': credits,
        'selected_percentage': selectedPercentage,
        'points': points,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: _stringValue(json['id'], fallback: _stringValue(json['player_id'], fallback: '')),
        name: _stringValue(json['name'], fallback: 'Unknown player'),
        team: _stringValue(json['team'], fallback: _stringValue(json['team_name'], fallback: '')),
        role: _normalizeRole(
          _stringValue(
            json['role'],
            fallback: _stringValue(
              json['playingRole'],
              fallback: _stringValue(json['designation'], fallback: 'BAT'),
            ),
          ),
        ),
        credits: _intValue(json['credits'], fallback: 8),
        selectedPercentage: _doubleValue(json['selectedPercentage'] ?? json['selected_percentage']),
        points: json['points'] == null ? null : _intValue(json['points']),
      );

  factory Player.fromCricApi(Map<String, dynamic> json, {required String team}) => Player(
        id: _stringValue(json['id'], fallback: _stringValue(json['playerId'], fallback: _stringValue(json['name']))),
        name: _stringValue(json['name'], fallback: 'Unknown player'),
        team: team,
        role: _normalizeRole(
          _stringValue(
            json['role'],
            fallback: _stringValue(
              json['playingRole'],
              fallback: _stringValue(json['speciality'], fallback: 'BAT'),
            ),
          ),
        ),
        credits: _intValue(json['credits'] ?? json['fantasyCredit'], fallback: 8),
        selectedPercentage: _doubleValue(
          json['selectedPercentage'] ?? json['selected_percentage'] ?? json['fantasyPlayerRating'],
        ),
        points: json['points'] == null ? null : _intValue(json['points']),
      );
}

class Team {
  final String id;
  final String userId;
  final String matchId;
  final String teamName;
  final List<Player> players;
  final String captainId;
  final String viceCaptainId;
  final int totalCredits;
  final DateTime? createdAt;

  const Team({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.teamName,
    required this.players,
    required this.captainId,
    required this.viceCaptainId,
    required this.totalCredits,
    this.createdAt,
  });

  String get captainName => _playerNameById(captainId);
  String get viceCaptainName => _playerNameById(viceCaptainId);

  String _playerNameById(String playerId) {
    for (final player in players) {
      if (player.id == playerId) {
        return player.name;
      }
    }
    return playerId;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'match_id': matchId,
        'team_name': teamName,
        'players': players.map((player) => player.toJson()).toList(),
        'captain_id': captainId,
        'vice_captain_id': viceCaptainId,
        'total_credits': totalCredits,
        'created_at': createdAt?.toIso8601String(),
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: _stringValue(json['id']),
        userId: _stringValue(json['user_id'], fallback: _stringValue(json['userId'])),
        matchId: _stringValue(json['match_id'], fallback: _stringValue(json['matchId'])),
        teamName: _stringValue(json['team_name'], fallback: _stringValue(json['teamName'], fallback: 'My Team')),
        players: _listOfMaps(json['players']).map(Player.fromJson).toList(),
        captainId: _stringValue(json['captain_id'], fallback: _stringValue(json['captainId'])),
        viceCaptainId: _stringValue(
          json['vice_captain_id'],
          fallback: _stringValue(json['viceCaptainId']),
        ),
        totalCredits: _intValue(json['total_credits'], fallback: _intValue(json['totalCredits'])),
        createdAt: _dateTimeValue(json['created_at']) ?? _dateTimeValue(json['createdAt']),
      );
}

class LeaderboardEntry {
  final String id;
  final String userId;
  final String matchId;
  final String teamId;
  final int totalPoints;
  final int rank;
  final String username;
  final String captainName;
  final DateTime? updatedAt;

  const LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.teamId,
    required this.totalPoints,
    required this.rank,
    required this.username,
    required this.captainName,
    this.updatedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        id: _stringValue(json['id']),
        userId: _stringValue(json['user_id'], fallback: _stringValue(json['userId'])),
        matchId: _stringValue(json['match_id'], fallback: _stringValue(json['matchId'])),
        teamId: _stringValue(json['team_id'], fallback: _stringValue(json['teamId'])),
        totalPoints: _intValue(json['total_points'], fallback: _intValue(json['totalPoints'])),
        rank: _intValue(json['rank']),
        username: _stringValue(json['username'], fallback: _stringValue(json['display_name'], fallback: 'Player')),
        captainName: _stringValue(
          json['captain_name'],
          fallback: _stringValue(json['captainName'], fallback: 'Captain'),
        ),
        updatedAt: _dateTimeValue(json['updated_at']) ?? _dateTimeValue(json['updatedAt']),
      );
}

class Contest {
  final String id;
  final String matchId;
  final String contestName;
  final int maxTeams;
  final int entryFee;
  final String prizeDescription;
  final DateTime? createdAt;

  const Contest({
    required this.id,
    required this.matchId,
    required this.contestName,
    required this.maxTeams,
    required this.entryFee,
    required this.prizeDescription,
    this.createdAt,
  });

  factory Contest.fromJson(Map<String, dynamic> json) => Contest(
        id: _stringValue(json['id']),
        matchId: _stringValue(json['match_id'], fallback: _stringValue(json['matchId'])),
        contestName: _stringValue(
          json['contest_name'],
          fallback: _stringValue(json['contestName'], fallback: 'Free Contest'),
        ),
        maxTeams: _intValue(json['max_teams'], fallback: _intValue(json['maxTeams'], fallback: 1)),
        entryFee: _intValue(json['entry_fee'], fallback: _intValue(json['entryFee'])),
        prizeDescription: _stringValue(
          json['prize_description'],
          fallback: _stringValue(json['prizeDescription'], fallback: 'No prize information available'),
        ),
        createdAt: _dateTimeValue(json['created_at']) ?? _dateTimeValue(json['createdAt']),
      );
}

class TeamDraft {
  final String? matchId;
  final List<Player> players;
  final String? captainId;
  final String? viceCaptainId;

  const TeamDraft({
    this.matchId,
    this.players = const [],
    this.captainId,
    this.viceCaptainId,
  });

  static const empty = TeamDraft();

  int get totalCredits => players.fold(0, (sum, player) => sum + player.credits);
  bool get hasElevenPlayers => players.length == 11;
  int get wicketKeeperCount => players.where((player) => player.role == 'WK').length;
  int get batterCount => players.where((player) => player.role == 'BAT').length;
  int get allRounderCount => players.where((player) => player.role == 'AR').length;
  int get bowlerCount => players.where((player) => player.role == 'BOWL').length;

  Map<String, int> get teamCounts {
    final counts = <String, int>{};
    for (final player in players) {
      counts[player.team] = (counts[player.team] ?? 0) + 1;
    }
    return counts;
  }

  List<String> get validationErrors {
    final errors = <String>[];

    if (!hasElevenPlayers) {
      errors.add('Select exactly 11 players.');
    }

    if (totalCredits > 100) {
      errors.add('Keep total credits within 100.');
    }

    final overloadedTeams = teamCounts.entries.where((entry) => entry.value > 7).toList();
    if (overloadedTeams.isNotEmpty) {
      errors.add('Use at most 7 players from one real team.');
    }

    if (wicketKeeperCount < 1) {
      errors.add('Pick at least 1 wicket-keeper.');
    }

    if (batterCount < 3) {
      errors.add('Pick at least 3 batters.');
    }

    if (allRounderCount < 1) {
      errors.add('Pick at least 1 all-rounder.');
    }

    if (bowlerCount < 3) {
      errors.add('Pick at least 3 bowlers.');
    }

    return errors;
  }

  bool get isValid {
    return validationErrors.isEmpty;
  }

  TeamDraft copyWith({
    String? matchId,
    List<Player>? players,
    String? captainId,
    String? viceCaptainId,
    bool clearCaptain = false,
    bool clearViceCaptain = false,
  }) {
    return TeamDraft(
      matchId: matchId ?? this.matchId,
      players: players ?? this.players,
      captainId: clearCaptain ? null : (captainId ?? this.captainId),
      viceCaptainId: clearViceCaptain ? null : (viceCaptainId ?? this.viceCaptainId),
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

String? _nullableStringValue(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
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

double? _doubleValue(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
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

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => item.map((key, entry) => MapEntry(key.toString(), entry)))
        .toList();
  }
  return const [];
}

List<String> _listOfStrings(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

String _normalizeRole(String rawRole) {
  final role = rawRole.toUpperCase();
  if (role.contains('WICKET') || role == 'WK') {
    return 'WK';
  }
  if (role.contains('ALL') || role == 'AR') {
    return 'AR';
  }
  if (role.contains('BOWL') || role == 'BWL') {
    return 'BOWL';
  }
  return 'BAT';
}

String _normalizeMatchStatus(String rawStatus) {
  final status = rawStatus.toUpperCase();
  if (status.contains('LIVE') ||
      status.contains('INNINGS') ||
      status.contains('REQUIRE') ||
      status.contains('NEED')) {
    return 'LIVE';
  }
  if (status.contains('RESULT') ||
      status.contains('WON') ||
      status.contains('DRAW') ||
      status.contains('TIED') ||
      status.contains('ABANDON') ||
      status.contains('NO RESULT') ||
      status.contains('COMPLETED')) {
    return 'COMPLETED';
  }
  return 'UPCOMING';
}

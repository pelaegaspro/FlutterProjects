class FantasyMatch {
  const FantasyMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.startTime,
    required this.venue,
    this.tournament,
  });

  final String id;
  final String teamA;
  final String teamB;
  final DateTime startTime;
  final String venue;
  final String? tournament;

  String get title => '$teamA vs $teamB';

  factory FantasyMatch.fromMap(Map<String, dynamic> map) {
    return FantasyMatch(
      id: map['id']?.toString() ?? map['matchId']?.toString() ?? '',
      teamA: map['teamA']?.toString() ?? map['team_a']?.toString() ?? 'Team A',
      teamB: map['teamB']?.toString() ?? map['team_b']?.toString() ?? 'Team B',
      startTime: DateTime.tryParse(
            map['matchTime']?.toString() ??
                map['match_time']?.toString() ??
                map['startTime']?.toString() ??
                '',
          )?.toLocal() ??
          DateTime.now(),
      venue: map['venue']?.toString() ?? 'Venue pending',
      tournament: map['tournament']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'teamA': teamA,
        'teamB': teamB,
        'matchTime': startTime.toIso8601String(),
        'venue': venue,
        'tournament': tournament,
      };
}

class FantasyPlayer {
  const FantasyPlayer({
    required this.id,
    required this.name,
    required this.team,
    required this.role,
    required this.credit,
    required this.last5Avg,
    required this.venueAvg,
    required this.opponentAvg,
  });

  final String id;
  final String name;
  final String team;
  final String role;
  final double credit;
  final double last5Avg;
  final double venueAvg;
  final double opponentAvg;

  double get projectedScore =>
      (last5Avg * 0.4) + (venueAvg * 0.3) + (opponentAvg * 0.3);

  factory FantasyPlayer.fromMap(Map<String, dynamic> map) {
    return FantasyPlayer(
      id: map['id']?.toString() ?? map['playerId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Player',
      team: map['team']?.toString() ?? map['teamName']?.toString() ?? 'Unknown',
      role: _normalizeRole(map['role']?.toString() ?? 'BAT'),
      credit: _toDouble(map['credit']) ?? 8,
      last5Avg: _toDouble(map['last5Avg']) ?? 0,
      venueAvg: _toDouble(map['venueAvg']) ?? 0,
      opponentAvg: _toDouble(map['opponentAvg']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'team': team,
        'role': role,
        'credit': credit,
        'last5Avg': last5Avg,
        'venueAvg': venueAvg,
        'opponentAvg': opponentAvg,
      };
}

double? _toDouble(dynamic value) {
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

String _normalizeRole(String rawRole) {
  final role = rawRole.toUpperCase();
  if (role.contains('WICKET') || role == 'WK') {
    return 'WK';
  }
  if (role.contains('ALL') || role == 'AR') {
    return 'AR';
  }
  if (role.contains('BOWL')) {
    return 'BOWL';
  }
  return 'BAT';
}

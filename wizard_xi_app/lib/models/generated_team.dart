import '../core/constants.dart';
import 'fantasy_player.dart';

class GeneratedTeam {
  const GeneratedTeam({
    required this.id,
    required this.teamNumber,
    required this.players,
    required this.captainId,
    required this.viceCaptainId,
  });

  final String id;
  final int teamNumber;
  final List<FantasyPlayer> players;
  final String captainId;
  final String viceCaptainId;

  double get totalCredits =>
      players.fold<double>(0, (sum, player) => sum + player.credit);

  double get totalProjection =>
      players.fold<double>(0, (sum, player) => sum + player.projectedScore);

  List<FantasyPlayer> playersForRole(String role) {
    final grouped = players.where((player) => player.role == role).toList()
      ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));
    return grouped;
  }

  FantasyPlayer playerById(String id) {
    return players.firstWhere((player) => player.id == id);
  }

  String get captainName => playerById(captainId).name;
  String get viceCaptainName => playerById(viceCaptainId).name;

  List<FantasyPlayer> get selectionOrder {
    final ordered = <FantasyPlayer>[];
    for (final role in AppConstants.roleOrder) {
      ordered.addAll(playersForRole(role));
    }
    return ordered;
  }

  String toCopyText() {
    final buffer = StringBuffer('TEAM $teamNumber\n');
    for (final role in AppConstants.roleOrder) {
      final names = playersForRole(role).map((player) => player.name).join(', ');
      buffer.writeln('$role: $names');
    }
    buffer.writeln('C: $captainName');
    buffer.writeln('VC: $viceCaptainName');
    return buffer.toString().trimRight();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'teamNumber': teamNumber,
        'players': players.map((player) => player.toMap()).toList(),
        'captainId': captainId,
        'viceCaptainId': viceCaptainId,
      };

  factory GeneratedTeam.fromMap(Map<String, dynamic> map) {
    final players = (map['players'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => FantasyPlayer.fromMap(item.cast<String, dynamic>()))
        .toList();

    return GeneratedTeam(
      id: map['id']?.toString() ?? '',
      teamNumber: int.tryParse(map['teamNumber']?.toString() ?? '') ?? 1,
      players: players,
      captainId: map['captainId']?.toString() ?? '',
      viceCaptainId: map['viceCaptainId']?.toString() ?? '',
    );
  }
}

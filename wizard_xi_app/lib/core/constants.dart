class AppConstants {
  static const appName = 'Wizard XI';
  static const batchSize = 20;
  static const maxPlayers = 11;
  static const maxCredits = 100.0;
  static const maxPlayersPerRealTeam = 7;
  static const teamCountOptions = <int>[10, 20, 50, 100];
  static const dream11Scheme = 'dream11://';
  static const dream11WebUrl = 'https://www.dream11.com/';
  static const roleOrder = <String>['WK', 'BAT', 'AR', 'BOWL'];

  static const roleLimits = <String, RoleLimit>{
    'WK': RoleLimit(min: 1, max: 4),
    'BAT': RoleLimit(min: 3, max: 6),
    'AR': RoleLimit(min: 1, max: 4),
    'BOWL': RoleLimit(min: 3, max: 6),
  };
}

class RoleLimit {
  const RoleLimit({
    required this.min,
    required this.max,
  });

  final int min;
  final int max;
}

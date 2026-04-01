import 'fantasy_player.dart';

class ExposureConfig {
  const ExposureConfig({
    this.maxExposure = const {},
    this.defaultMaxExposurePercent = 80,
  });

  final Map<String, double> maxExposure;
  final double defaultMaxExposurePercent;

  double maxExposureFor(FantasyPlayer player) {
    return maxExposure[player.id] ??
        maxExposure[player.name] ??
        defaultMaxExposurePercent;
  }

  Map<String, dynamic> toMap() => {
        'maxExposure': maxExposure,
        'defaultMaxExposurePercent': defaultMaxExposurePercent,
      };

  factory ExposureConfig.fromMap(Map<String, dynamic> map) {
    final rawExposure = (map['maxExposure'] as Map<dynamic, dynamic>? ?? const {});

    return ExposureConfig(
      maxExposure: {
        for (final entry in rawExposure.entries)
          entry.key.toString(): _toDouble(entry.value) ?? 80,
      },
      defaultMaxExposurePercent:
          _toDouble(map['defaultMaxExposurePercent']) ?? 80,
    );
  }

  factory ExposureConfig.smartDefaults(List<FantasyPlayer> players) {
    final sorted = [...players]
      ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));

    final maxExposure = <String, double>{};
    for (var index = 0; index < sorted.length; index++) {
      final percentile = sorted.isEmpty ? 0 : index / sorted.length;
      if (percentile < 0.25) {
        maxExposure[sorted[index].id] = 75;
      } else if (percentile < 0.75) {
        maxExposure[sorted[index].id] = 60;
      } else {
        maxExposure[sorted[index].id] = 40;
      }
    }

    return ExposureConfig(
      maxExposure: maxExposure,
      defaultMaxExposurePercent: 60,
    );
  }

  factory ExposureConfig.fromPlayers({
    required List<FantasyPlayer> players,
    required double globalExposurePercent,
    Map<String, double> overrides = const {},
  }) {
    final defaults = ExposureConfig.smartDefaults(players);
    final cappedExposure = <String, double>{};

    for (final player in players) {
      final defaultExposure = defaults.maxExposureFor(player);
      final override = overrides[player.id] ?? overrides[player.name];
      final effectiveExposure = ((override ?? defaultExposure)
              .clamp(0.0, globalExposurePercent))
          .toDouble();
      cappedExposure[player.id] = effectiveExposure;
    }

    return ExposureConfig(
      maxExposure: cappedExposure,
      defaultMaxExposurePercent: globalExposurePercent,
    );
  }
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

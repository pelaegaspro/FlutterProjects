import '../core/constants.dart';
import 'generated_team.dart';

class TeamGenerationState {
  const TeamGenerationState({
    this.requestedCount = 20,
    this.globalExposurePercent = 70,
    this.exposureOverrides = const {},
    this.lastGenerationSeed,
    this.currentBatchIndex = 0,
    this.isGenerating = false,
    this.generatedTeams = const [],
    this.errorMessage,
    this.warningMessage,
  });

  final int requestedCount;
  final double globalExposurePercent;
  final Map<String, double> exposureOverrides;
  final int? lastGenerationSeed;
  final int currentBatchIndex;
  final bool isGenerating;
  final List<GeneratedTeam> generatedTeams;
  final String? errorMessage;
  final String? warningMessage;

  int get totalBatches {
    if (generatedTeams.isEmpty) {
      return 0;
    }
    return ((generatedTeams.length - 1) ~/ AppConstants.batchSize) + 1;
  }

  int get pageStart => currentBatchIndex * AppConstants.batchSize;

  int get pageEnd {
    final value = pageStart + AppConstants.batchSize;
    return value > generatedTeams.length ? generatedTeams.length : value;
  }

  List<GeneratedTeam> get currentBatch {
    if (generatedTeams.isEmpty) {
      return const [];
    }
    return generatedTeams.sublist(pageStart, pageEnd);
  }

  TeamGenerationState copyWith({
    int? requestedCount,
    double? globalExposurePercent,
    Map<String, double>? exposureOverrides,
    int? lastGenerationSeed,
    int? currentBatchIndex,
    bool? isGenerating,
    List<GeneratedTeam>? generatedTeams,
    String? errorMessage,
    String? warningMessage,
    bool clearError = false,
    bool clearWarning = false,
  }) {
    return TeamGenerationState(
      requestedCount: requestedCount ?? this.requestedCount,
      globalExposurePercent:
          globalExposurePercent ?? this.globalExposurePercent,
      exposureOverrides: exposureOverrides ?? this.exposureOverrides,
      lastGenerationSeed: lastGenerationSeed ?? this.lastGenerationSeed,
      currentBatchIndex: currentBatchIndex ?? this.currentBatchIndex,
      isGenerating: isGenerating ?? this.isGenerating,
      generatedTeams: generatedTeams ?? this.generatedTeams,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      warningMessage:
          clearWarning ? null : (warningMessage ?? this.warningMessage),
    );
  }
}

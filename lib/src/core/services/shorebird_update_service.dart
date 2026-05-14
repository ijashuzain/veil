import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

enum ShorebirdPatchStage {
  checking,
  downloading,
  upToDate,
  unavailable,
  restartRequired,
  failed,
}

class ShorebirdPatchResult {
  const ShorebirdPatchResult({
    required this.stage,
    this.restartRequired = false,
    this.message,
  });

  final ShorebirdPatchStage stage;
  final bool restartRequired;
  final String? message;
}

abstract interface class ShorebirdUpdateService {
  Future<ShorebirdPatchResult> checkAndDownloadPatch({
    void Function(ShorebirdPatchStage stage)? onStageChanged,
  });
}

class NoopShorebirdUpdateService implements ShorebirdUpdateService {
  const NoopShorebirdUpdateService();

  @override
  Future<ShorebirdPatchResult> checkAndDownloadPatch({
    void Function(ShorebirdPatchStage stage)? onStageChanged,
  }) async {
    return const ShorebirdPatchResult(stage: ShorebirdPatchStage.unavailable);
  }
}

class ShorebirdCodePushUpdateService implements ShorebirdUpdateService {
  ShorebirdCodePushUpdateService({ShorebirdUpdater? updater})
    : _updater = updater ?? ShorebirdUpdater();

  final ShorebirdUpdater _updater;

  @override
  Future<ShorebirdPatchResult> checkAndDownloadPatch({
    void Function(ShorebirdPatchStage stage)? onStageChanged,
  }) async {
    try {
      if (!_updater.isAvailable) {
        return const ShorebirdPatchResult(
          stage: ShorebirdPatchStage.unavailable,
        );
      }

      onStageChanged?.call(ShorebirdPatchStage.checking);
      final status = await _updater.checkForUpdate();

      switch (status) {
        case UpdateStatus.upToDate:
          return const ShorebirdPatchResult(
            stage: ShorebirdPatchStage.upToDate,
          );
        case UpdateStatus.unavailable:
          return const ShorebirdPatchResult(
            stage: ShorebirdPatchStage.unavailable,
          );
        case UpdateStatus.restartRequired:
          return const ShorebirdPatchResult(
            stage: ShorebirdPatchStage.restartRequired,
            restartRequired: true,
          );
        case UpdateStatus.outdated:
          onStageChanged?.call(ShorebirdPatchStage.downloading);
          await _updater.update();
          return const ShorebirdPatchResult(
            stage: ShorebirdPatchStage.restartRequired,
            restartRequired: true,
          );
      }
    } catch (error, stackTrace) {
      debugPrint('Shorebird update check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return ShorebirdPatchResult(
        stage: ShorebirdPatchStage.failed,
        message: error.toString(),
      );
    }
  }
}

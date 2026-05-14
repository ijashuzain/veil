import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/core/services/shorebird_update_service.dart';
import 'package:veil/src/shared/components/shorebird_update_gate.dart';

void main() {
  testWidgets('downloads an available Shorebird patch before app launch', (
    tester,
  ) async {
    final service = _FakeShorebirdUpdateService();

    await tester.pumpWidget(
      MaterialApp(
        home: ShorebirdUpdateGate(
          updateService: service,
          child: const Text('App ready'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Checking for updates'), findsOneWidget);
    expect(find.text('App ready'), findsNothing);

    service.emit(ShorebirdPatchStage.downloading);
    await tester.pump();

    expect(find.text('Downloading update'), findsOneWidget);

    service.complete(
      const ShorebirdPatchResult(
        stage: ShorebirdPatchStage.restartRequired,
        restartRequired: true,
      ),
    );
    await tester.pump();

    expect(find.text('Update installed'), findsOneWidget);
    expect(
      find.text('Restart Veil to apply the latest patch.'),
      findsOneWidget,
    );
    expect(find.text('App ready'), findsNothing);
  });
}

class _FakeShorebirdUpdateService implements ShorebirdUpdateService {
  final _completer = Completer<ShorebirdPatchResult>();
  void Function(ShorebirdPatchStage stage)? _onStageChanged;

  @override
  Future<ShorebirdPatchResult> checkAndDownloadPatch({
    void Function(ShorebirdPatchStage stage)? onStageChanged,
  }) {
    _onStageChanged = onStageChanged;
    _onStageChanged?.call(ShorebirdPatchStage.checking);
    return _completer.future;
  }

  void emit(ShorebirdPatchStage stage) {
    _onStageChanged?.call(stage);
  }

  void complete(ShorebirdPatchResult result) {
    _completer.complete(result);
  }
}

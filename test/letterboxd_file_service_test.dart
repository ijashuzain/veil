import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/letterboxd/models/letterboxd_import_export.dart';
import 'package:veil/src/features/letterboxd/services/letterboxd_file_service.dart';

void main() {
  test(
    'native fallback reports file access limitation without plugin channel',
    () {
      const service = LetterboxdFileService();

      expect(
        service.pickImportFiles,
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('full store build'),
          ),
        ),
      );
      expect(
        () => service.saveExport(
          LetterboxdExportBundle(
            fileName: 'veil-letterboxd-export.zip',
            bytes: Uint8List(0),
            activityCount: 0,
            watchlistCount: 0,
            unsupportedCount: 0,
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    },
  );

  test('web picker does not infer cancellation from window focus', () {
    final source = File(
      'lib/src/features/letterboxd/services/letterboxd_file_service_web.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('window.onFocus')));
    expect(source, contains("input.on['cancel']"));
  });
}

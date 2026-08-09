import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TMDB function allows watch provider routes', () async {
    final source = await File(
      'supabase/functions/tmdb/index.ts',
    ).readAsString();
    expect(source, contains("  'watch',"));
    expect(source, contains('return allowedRoutes.has(segments[1]);'));
  });

  test('TMDB image function allows w200 and keeps size allowlist', () async {
    final source = await File(
      'supabase/functions/tmdb-image/index.ts',
    ).readAsString();
    expect(source, contains("  'w200',"));
    expect(
      source,
      contains('if (!allowedSizes.has(segments[2])) return false;'),
    );
    expect(source, contains("segment !== '..'"));
  });
}

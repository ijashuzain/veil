import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web shell keeps mobile PWA chrome and exposed viewport dark', () {
    final index = File('web/index.html').readAsStringSync();
    final serviceWorker = File('web/veil_service_worker.js').readAsStringSync();
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final firebase =
        jsonDecode(File('firebase.json').readAsStringSync())
            as Map<String, dynamic>;

    expect(index, contains('<meta name="theme-color" content="#050507">'));
    expect(index, contains('viewport-fit=cover'));
    expect(index, contains('background: #050507'));
    expect(index, contains('visualViewport'));
    expect(index, contains('pageshow'));
    expect(index, contains('flutter_bootstrap.js?v=20260509-viewport'));
    expect(manifest['theme_color'], '#050507');
    expect(manifest['background_color'], '#050507');
    expect(
      serviceWorker,
      contains("const CACHE_NAME = 'veil-pwa-v20260509-viewport';"),
    );
    expect(_hasNoCacheHeader(firebase, '/'), isTrue);
  });
}

bool _hasNoCacheHeader(Map<String, dynamic> firebase, String source) {
  final hosting = firebase['hosting'] as Map<String, dynamic>;
  final headerRules = hosting['headers'] as List<dynamic>;

  return headerRules.any((rule) {
    final headerRule = rule as Map<String, dynamic>;
    if (headerRule['source'] != source) return false;

    final headers = headerRule['headers'] as List<dynamic>;
    return headers.any((header) {
      final values = header as Map<String, dynamic>;
      return values['key'] == 'Cache-Control' &&
          values['value'] == 'no-cache, no-store, must-revalidate';
    });
  });
}

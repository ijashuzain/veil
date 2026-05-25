import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veil/src/features/embeded_player/utils/direct_stream_availability.dart';

void main() {
  test('direct stream availability rejects non-200 playlists', () async {
    final available = await isDirectStreamAvailable(
      Uri.parse('https://example.test/proxy.m3u8'),
      client: MockClient((_) async => http.Response('#EXTM3U', 404)),
    );

    expect(available, isFalse);
  });

  test('direct stream availability rejects not available playlists', () async {
    final available = await isDirectStreamAvailable(
      Uri.parse('https://example.test/proxy.m3u8'),
      client: MockClient(
        (_) async => http.Response('#EXTM3U\n# not available', 200),
      ),
    );

    expect(available, isFalse);
  });

  test(
    'direct stream availability accepts playable master playlists',
    () async {
      final available = await isDirectStreamAvailable(
        Uri.parse('https://example.test/proxy.m3u8'),
        client: MockClient(
          (_) async => http.Response(
            '#EXTM3U\n'
            '#EXT-X-STREAM-INF:BANDWIDTH=2149280\n'
            'https://example.test/variant.m3u8\n',
            200,
          ),
        ),
      );

      expect(available, isTrue);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/repository/subtitle_repository.dart';

void main() {
  for (final status in [403, 404, 500]) {
    test('reports subtitle HTTP $status', () async {
      final repository = SubtitleRepository(
        client: MockClient((_) async => http.Response('', status)),
      );
      addTearDown(repository.dispose);
      await expectLater(
        repository.load(
          StreamSubtitle(
            url: Uri.parse('https://subs.test/en.srt'),
            label: 'English',
          ),
          ResolvedStream(
            url: Uri.parse('https://player.test/master.m3u8'),
            format: NativeStreamFormat.hls,
            headers: {},
            resolvedAt: DateTime.now(),
          ),
        ),
        throwsA(
          isA<StreamResolutionException>().having(
            (e) => e.message,
            'message',
            contains('HTTP $status'),
          ),
        ),
      );
    });
  }

  test('distinguishes HTML response from unreadable captions', () async {
    final repository = SubtitleRepository(
      client: MockClient(
        (_) async => http.Response('<html>Access denied</html>', 200),
      ),
    );
    addTearDown(repository.dispose);
    await expectLater(
      repository.load(
        StreamSubtitle(
          url: Uri.parse('https://subs.test/en.srt'),
          label: 'English',
        ),
        ResolvedStream(
          url: Uri.parse('https://player.test/master.m3u8'),
          format: NativeStreamFormat.hls,
          headers: {},
          resolvedAt: DateTime.now(),
        ),
      ),
      throwsA(
        isA<StreamResolutionException>().having(
          (e) => e.message,
          'message',
          contains('web page'),
        ),
      ),
    );
  });
  test('loads VTT without leaking playback cookies to subtitle CDN', () async {
    final repository = SubtitleRepository(
      client: MockClient((request) async {
        expect(request.headers.containsKey('Cookie'), isFalse);
        return http.Response(
          'WEBVTT\n\n00:00:01.000 --> 00:00:03.000\nHello\n',
          200,
        );
      }),
    );
    final stream = ResolvedStream(
      url: Uri.parse('https://player.test/master.m3u8'),
      format: NativeStreamFormat.hls,
      headers: {'Cookie': 'session=private'},
      resolvedAt: DateTime.now(),
    );
    final captions = await repository.load(
      StreamSubtitle(
        url: Uri.parse('https://subs.test/en.vtt'),
        label: 'English',
      ),
      stream,
    );
    expect(captions.captions.single.text, 'Hello');
    repository.dispose();
  });
}

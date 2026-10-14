import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/repository/shared_subtitle_repository.dart';
import 'package:veil/src/features/native_player/repository/subtitle_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/models/playback_request.dart';

const movie = ContentItem(
  id: 'movie-969681',
  remoteId: 969681,
  mediaType: 'movie',
  title: 'Spider-Man: Brand New Day',
  subtitle: '',
  year: 2026,
  genre: '',
  type: 'Movie',
  rating: 0,
  palette: [],
  glyph: Icons.movie,
  description: '',
);

void main() {
  test('search and cache use title identity across both players', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(request.url.queryParameters['tmdb_id'], '969681');
      expect(request.url.queryParameters['type'], 'movie');
      expect(request.headers['authorization'], 'Bearer user-session');
      return http.Response(
        jsonEncode({
          'tracks': [
            {
              'downloadUrl': 'https://sub.wyzie.io/c/test/id/123',
              'language': 'en',
              'release': 'WEB 1080p',
            },
          ],
        }),
        200,
      );
    });
    final repository = SharedSubtitleRepository(
      client: client,
      endpoint: Uri.parse('https://backend.test/subtitles'),
      accessToken: () => 'user-session',
    );
    final first = await repository.search(
      const PlaybackRequest(item: movie, server: PlaybackServer.five),
    );
    final second = await repository.search(
      const PlaybackRequest(item: movie, server: PlaybackServer.six),
    );
    expect(calls, 1);
    expect(first.single.url, second.single.url);
    expect(first.single.source, 'Wyzie');
    expect(first.single.release, 'WEB 1080p');
    expect(
      first.single.url.queryParameters['url'],
      'https://sub.wyzie.io/c/test/id/123',
    );
    client.close();
  });

  test('series searches include selected season and episode', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['type'], 'episode');
      expect(request.url.queryParameters['season'], '2');
      expect(request.url.queryParameters['episode'], '3');
      return http.Response('{"tracks":[]}', 200);
    });
    final repository = SharedSubtitleRepository(
      client: client,
      accessToken: () => 'user-session',
    );
    await repository.search(
      PlaybackRequest(
        item: movie.copyWith(mediaType: 'tv', type: 'Series'),
        server: PlaybackServer.six,
        season: 2,
        episode: 3,
      ),
    );
    client.close();
  });

  test('shared outage keeps provider subtitles usable', () async {
    final client = MockClient((request) async => http.Response('', 503));
    final shared = SharedSubtitleRepository(
      client: client,
      accessToken: () => 'user-session',
    );
    final repository = SubtitleRepository(client: client, shared: shared);
    final fallback = StreamSubtitle(
      url: Uri.parse('https://provider.test/en.vtt'),
      label: 'English',
    );
    final stream = ResolvedStream(
      url: Uri.parse('https://video.test/master.m3u8'),
      format: NativeStreamFormat.hls,
      headers: {},
      resolvedAt: DateTime.now(),
      subtitles: [fallback],
    );
    expect(
      await repository.discoverForPlayback(
        stream,
        const PlaybackRequest(item: movie, server: PlaybackServer.five),
      ),
      [fallback],
    );
    repository.dispose();
  });

  test('shared download uses app session and caches parsed captions', () async {
    var downloads = 0;
    final client = MockClient((request) async {
      downloads++;
      expect(request.headers['authorization'], 'Bearer user-session');
      expect(request.headers.containsKey('cookie'), isFalse);
      return http.Response('1\n00:00:01,000 --> 00:00:03,000\nHello\n', 200);
    });
    final endpoint = Uri.parse('https://backend.test/subtitles');
    final repository = SubtitleRepository(
      client: client,
      shared: SharedSubtitleRepository(
        client: client,
        endpoint: endpoint,
        accessToken: () => 'user-session',
      ),
    );
    final track = StreamSubtitle(
      url: endpoint.replace(
        queryParameters: {
          'action': 'download',
          'url': 'https://sub.wyzie.io/c/test/id/123',
        },
      ),
      label: 'English',
      source: 'Wyzie',
    );
    final stream = ResolvedStream(
      url: Uri.parse('https://video.test/master.m3u8'),
      format: NativeStreamFormat.hls,
      headers: {'Cookie': 'private'},
      resolvedAt: DateTime.now(),
    );
    expect(
      (await repository.load(track, stream)).captions.single.text,
      'Hello',
    );
    await repository.load(track, stream);
    expect(downloads, 1);
    repository.dispose();
  });
}

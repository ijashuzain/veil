import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/detail/utils/playback_entry_url.dart';
import 'package:veil/src/features/embeded_player/utils/playback_target.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/models/playback_request.dart';

void main() {
  test('playback request clamps season and episode', () {
    const request = PlaybackRequest(
      item: _tv,
      server: PlaybackServer.two,
      season: 0,
      episode: -2,
    );

    expect(request.safeSeason, 1);
    expect(request.safeEpisode, 1);
  });

  test('cinejoy uses TMDB movie and episode paths', () {
    expect(
      cinejoyPlaybackUrl(tmdbId: 1284041, contentType: 'Movie').toString(),
      'https://cinejoy.to/watch/movie/1284041',
    );
    expect(
      cinejoyPlaybackUrl(
        tmdbId: 94997,
        contentType: 'TV Show',
        season: 0,
        episode: -2,
      ).toString(),
      'https://cinejoy.to/watch/tv/94997/1/1',
    );
    expect(cinejoyPlaybackUrl(tmdbId: 0, contentType: 'Movie'), isNull);
  });

  test('server one keeps Vidsrc target policy', () {
    final target = playbackTargetFor(
      const PlaybackRequest(
        item: _tv,
        server: PlaybackServer.one,
        season: 2,
        episode: 3,
      ),
    )!;

    expect(
      target.url.toString(),
      'https://vidsrc-embed.ru/embed/tv?tmdb=94997&season=2&episode=3&autoplay=1&autonext=1',
    );
    expect(target.fallbackUrls, isEmpty);
    expect(target.forceEmbedded, isTrue);
    expect(target.loadAsPage, isTrue);
    expect(target.externalOnWeb, isFalse);
  });

  test('server two target is top-level native and external on web', () {
    final target = playbackTargetFor(
      const PlaybackRequest(item: _movie, server: PlaybackServer.two),
    )!;

    expect(target.url.toString(), 'https://cinejoy.to/watch/movie/1284041');
    expect(target.loadAsPage, isTrue);
    expect(target.externalOnWeb, isTrue);
    expect(target.fallbackUrls, isEmpty);
    expect(target.forceEmbedded, isFalse);
  });

  test('server three keeps Cinesrc target policy and fixed first episode', () {
    final target = playbackTargetFor(
      const PlaybackRequest(
        item: _tv,
        server: PlaybackServer.three,
        season: 2,
        episode: 3,
      ),
    )!;

    expect(target.url.toString(), 'https://cinesrc.st/embed/tv/94997?s=1&e=1');
    expect(target.fallbackUrls, isEmpty);
    expect(target.forceEmbedded, isTrue);
    expect(target.loadAsPage, isFalse);
    expect(target.externalOnWeb, isFalse);
  });

  test('server four keeps VidLink target policy', () {
    final target = playbackTargetFor(
      const PlaybackRequest(
        item: _tv,
        server: PlaybackServer.four,
        season: 2,
        episode: 3,
      ),
    )!;

    expect(
      target.url.toString(),
      'https://vidlink.pro/tv/94997/2/3?player=jw&primaryColor=FFFFFF&secondaryColor=253034&iconColor=FFFFFF',
    );
    expect(target.fallbackUrls, isEmpty);
    expect(target.forceEmbedded, isTrue);
    expect(target.loadAsPage, isTrue);
    expect(target.externalOnWeb, isFalse);
  });

  test('targets return null when required ids are unavailable', () {
    for (final server in PlaybackServer.values) {
      expect(
        playbackTargetFor(PlaybackRequest(item: _missingIds, server: server)),
        isNull,
      );
    }
  });
}

const _movie = ContentItem(
  id: 'movie-1284041',
  title: 'Movie',
  subtitle: '',
  year: 2026,
  genre: 'Drama',
  type: 'Movie',
  rating: 8,
  palette: [Colors.black, Colors.red],
  glyph: Icons.movie_rounded,
  description: 'Movie fixture',
  remoteId: 1284041,
  imdbId: 'tt1234567',
);

const _tv = ContentItem(
  id: 'tv-94997',
  title: 'TV Show',
  subtitle: '',
  year: 2026,
  genre: 'Drama',
  type: 'TV Show',
  rating: 8,
  palette: [Colors.black, Colors.red],
  glyph: Icons.live_tv_rounded,
  description: 'TV fixture',
  remoteId: 94997,
  imdbId: 'tt7654321',
);

const _missingIds = ContentItem(
  id: 'missing',
  title: 'Missing',
  subtitle: '',
  year: 2026,
  genre: 'Drama',
  type: 'Movie',
  rating: 0,
  palette: [Colors.black, Colors.red],
  glyph: Icons.movie_rounded,
  description: 'Missing ID fixture',
  remoteId: 0,
);

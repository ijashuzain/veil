import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/repository/shared_subtitle_repository.dart';
import 'package:veil/src/shared/models/playback_request.dart';

class SubtitleRepository {
  SubtitleRepository({http.Client? client, SharedSubtitleRepository? shared})
    : _client = client ?? http.Client(),
      _providedShared = shared;
  final http.Client _client;
  final SharedSubtitleRepository? _providedShared;
  final _cache = <Uri, ClosedCaptionFile>{};
  final _tracks = <Uri, List<StreamSubtitle>>{};
  late final _shared =
      _providedShared ?? SharedSubtitleRepository(client: _client);

  Future<List<StreamSubtitle>> discoverForPlayback(
    ResolvedStream stream,
    PlaybackRequest? request,
  ) async {
    final primary = <StreamSubtitle>[];
    if (request != null) {
      try {
        primary.addAll(await _shared.search(request));
      } catch (_) {
        /* Provider tracks remain available. */
      }
    }
    var fallback = stream.subtitles;
    try {
      fallback = await discover(stream);
    } catch (_) {
      /* Keep captured tracks. */
    }
    return [...primary, ...fallback];
  }

  Future<List<StreamSubtitle>> discover(ResolvedStream stream) async {
    if (_tracks.containsKey(stream.url)) return _tracks[stream.url]!;
    final tracks = [...stream.subtitles];
    void collect(Object? value, int depth) {
      if (depth > 6) return;
      if (value is List) {
        for (final child in value.take(200)) {
          collect(child, depth + 1);
        }
      }
      if (value is! Map) return;
      final raw =
          value['url'] ?? value['file'] ?? value['src'] ?? value['downloadUrl'];
      final url = raw is String ? Uri.tryParse(raw) : null;
      if (url?.scheme == 'https' && !tracks.any((track) => track.url == url)) {
        tracks.add(
          StreamSubtitle(
            url: url!,
            label:
                (value['label'] ??
                        value['language'] ??
                        value['lang'] ??
                        'Subtitles')
                    .toString(),
            language: (value['language'] ?? value['lang'] ?? '').toString(),
          ),
        );
      }
      for (final child in value.values) {
        collect(child, depth + 1);
      }
    }

    for (final request in stream.subtitleRequests.take(2)) {
      if (request.url.scheme != 'https' ||
          request.url.host != 'cinesrc.st' ||
          request.url.path != '/api/subtitles/search') {
        continue;
      }
      final headers = {...stream.headers, 'content-type': 'application/json'};
      final response =
          await (request.method.toUpperCase() == 'POST'
                  ? _client.post(
                      request.url,
                      headers: headers,
                      body: request.body,
                    )
                  : _client.get(request.url, headers: headers))
              .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) collect(jsonDecode(response.body), 0);
    }
    return _tracks[stream.url] = tracks;
  }

  Future<ClosedCaptionFile> load(
    StreamSubtitle subtitle,
    ResolvedStream stream,
  ) async {
    if (_cache.containsKey(subtitle.url)) return _cache[subtitle.url]!;
    // Do not leak provider cookies/authorization to unrelated subtitle hosts.
    final headers =
        subtitle.source != 'provider' &&
            subtitle.url.origin == _shared.endpoint.origin
        ? _shared.headers
        : subtitle.url.origin == stream.url.origin
        ? stream.headers
        : <String, String>{};
    final response = await _client
        .get(subtitle.url, headers: headers)
        .timeout(Duration(seconds: subtitle.source != 'provider' ? 50 : 10));
    if (response.statusCode != 200) {
      if (subtitle.source == 'Wyzie' && response.statusCode == 429) {
        throw const StreamResolutionException(
          'Subtitle service is rate limited. Try a provider track.',
        );
      }
      throw StreamResolutionException(
        'Subtitle download failed (HTTP ${response.statusCode}). Try another track.',
      );
    }
    final body = utf8
        .decode(response.bodyBytes, allowMalformed: true)
        .replaceFirst(RegExp(r'^\uFEFF'), '')
        .trimLeft();
    if (body.isEmpty) {
      throw const StreamResolutionException(
        'This subtitle file is empty. Try another track.',
      );
    }
    if ((response.headers['content-type'] ?? '').contains('text/html') ||
        RegExp(
          r'^<(?:!doctype\s+html|html\b)',
          caseSensitive: false,
        ).hasMatch(body)) {
      throw const StreamResolutionException(
        'The subtitle server returned a web page instead of captions. Try another track.',
      );
    }
    if (body.startsWith('#EXTM3U')) {
      throw const StreamResolutionException(
        'Segmented subtitles require the embedded player.',
      );
    }
    final ClosedCaptionFile captions = body.startsWith('WEBVTT')
        ? WebVTTCaptionFile(body)
        : SubRipCaptionFile(body);
    if (captions.captions.isEmpty) {
      throw const StreamResolutionException(
        'No readable captions in this subtitle.',
      );
    }
    return _cache[subtitle.url] = captions;
  }

  void dispose() {
    _client.close();
    _cache.clear();
    _tracks.clear();
  }
}

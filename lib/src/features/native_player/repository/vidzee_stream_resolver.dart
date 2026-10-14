import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veil/src/features/native_player/models/resolved_stream.dart';

/// Public resolver demonstrated by api.vz.raphsm4.dev. Treat successful JSON as
/// candidates, not playable media: some endpoints return 200 with invalid HLS.
class VidzeeStreamResolver implements StreamResolver {
  VidzeeStreamResolver({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;
  bool _disposed = false;
  @override
  Future<ResolvedStream> resolve(Uri entryUrl) async {
    final segments = entryUrl.pathSegments;
    if (segments.length < 3 || !{'movie', 'tv'}.contains(segments[1])) {
      throw const StreamResolutionException('Invalid content identity.');
    }
    final query = {
      'id': segments[2],
      'type': segments[1],
      if (segments[1] == 'tv') ...{
        'season': entryUrl.queryParameters['s'] ?? '1',
        'episode': entryUrl.queryParameters['e'] ?? '1',
      },
    };
    final response = await _client
        .get(Uri.https('api.vz.raphsm4.dev', '/resolve', query))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 || _disposed) {
      throw const StreamResolutionException('Vidzee resolver unavailable.');
    }
    final data = jsonDecode(response.body);
    if (data is! Map || data['success'] != true || data['sources'] is! List) {
      throw const StreamResolutionException(
        'Vidzee has no sources for this title.',
      );
    }
    final subtitles = <StreamSubtitle>[];
    if (data['subtitles'] is List) {
      for (final raw in data['subtitles'] as List) {
        if (raw is! Map) continue;
        final url = Uri.tryParse(raw['url']?.toString() ?? '');
        if (url?.scheme == 'https') {
          subtitles.add(
            StreamSubtitle(
              url: url!,
              label: raw['label']?.toString() ?? 'Subtitles',
              language: raw['language']?.toString() ?? '',
            ),
          );
        }
      }
    }
    for (final raw in (data['sources'] as List).take(3)) {
      if (_disposed) {
        throw const StreamResolutionException('Resolution cancelled.');
      }
      if (raw is! Map || raw['language'] == 'Hindi') continue;
      final url = Uri.tryParse(raw['url']?.toString() ?? '');
      if (url == null ||
          url.scheme != 'https' ||
          url.host != 'api.vz.raphsm4.dev' ||
          url.path != '/proxy') {
        continue;
      }
      try {
        final manifest = await _client
            .get(url)
            .timeout(const Duration(seconds: 8));
        if (manifest.statusCode != 200 ||
            !isUsableHlsCandidate(url, manifest.body)) {
          continue;
        }
        final selected = preferredNativeHlsUrl(url, manifest.body);
        if (!isUsableHlsCandidate(selected, manifest.body)) continue;
        return ResolvedStream(
          url: selected,
          masterUrl: url,
          format: NativeStreamFormat.hls,
          headers: const {},
          resolvedAt: DateTime.now(),
          provider: 'vidzee:${raw['server']}',
          qualities: parseHlsQualities(url, manifest.body),
          subtitles: subtitles,
        );
      } catch (_) {
        if (_disposed) rethrow;
      }
    }
    throw const StreamResolutionException(
      'Vidzee returned no valid HLS playlist.',
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _client.close();
  }
}

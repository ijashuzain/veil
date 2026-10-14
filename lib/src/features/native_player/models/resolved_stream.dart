enum NativeStreamFormat { hls, mp4 }

class ResolvedStream {
  ResolvedStream({
    required this.url,
    required this.format,
    required Map<String, String> headers,
    required this.resolvedAt,
    this.masterUrl,
    this.provider = 'cinesrc',
    this.qualities = const [],
    this.subtitles = const [],
    this.subtitleRequests = const [],
  }) : headers = Map.unmodifiable(headers);

  final Uri url;
  final NativeStreamFormat format;
  final Map<String, String> headers;
  final DateTime resolvedAt;
  final Uri? masterUrl;
  final String provider;
  final List<StreamQuality> qualities;
  final List<StreamSubtitle> subtitles;
  final List<SubtitleRequest> subtitleRequests;

  ResolvedStream withUrl(Uri selected) => ResolvedStream(
    url: selected,
    format: format,
    headers: headers,
    resolvedAt: resolvedAt,
    masterUrl: masterUrl,
    provider: provider,
    qualities: qualities,
    subtitles: subtitles,
    subtitleRequests: subtitleRequests,
  );
}

class SubtitleRequest {
  const SubtitleRequest({required this.url, this.method = 'GET', this.body});
  final Uri url;
  final String method;
  final String? body;
}

class StreamQuality {
  const StreamQuality({
    required this.url,
    required this.height,
    this.bitrate = 0,
    this.codecs = '',
  });
  final Uri url;
  final int height;
  final int bitrate;
  final String codecs;
  String get label => height > 0 ? '${height}p' : '${bitrate ~/ 1000} kbps';
}

class StreamSubtitle {
  const StreamSubtitle({
    required this.url,
    required this.label,
    this.language = '',
    this.source = 'provider',
    this.release = '',
  });
  final Uri url;
  final String label;
  final String language;
  final String source;
  final String release;
}

Map<String, String> hlsAttributes(String line) => {
  for (final match in RegExp(r'([A-Z0-9-]+)=("[^"]*"|[^,]*)').allMatches(line))
    match.group(1)!: match.group(2)!.replaceAll('"', ''),
};

List<StreamQuality> parseHlsQualities(Uri master, String playlist) {
  final result = <StreamQuality>[];
  Map<String, String>? attributes;
  for (final line in playlist.split('\n').map((line) => line.trim())) {
    if (line.startsWith('#EXT-X-STREAM-INF:')) {
      attributes = hlsAttributes(line);
      continue;
    }
    if (attributes == null || line.isEmpty || line.startsWith('#')) continue;
    final url = master.resolve(line);
    if (isUsableHlsCandidate(url, playlist) &&
        !attributes.containsKey('AUDIO') &&
        !attributes.containsKey('SUBTITLES')) {
      result.add(
        StreamQuality(
          url: url,
          height:
              int.tryParse((attributes['RESOLUTION'] ?? '').split('x').last) ??
              0,
          bitrate: int.tryParse(attributes['BANDWIDTH'] ?? '') ?? 0,
          codecs: attributes['CODECS'] ?? '',
        ),
      );
    }
    attributes = null;
  }
  return result..sort((a, b) => a.bitrate.compareTo(b.bitrate));
}

List<StreamSubtitle> parseHlsSubtitles(Uri master, String playlist) {
  final result = <StreamSubtitle>[];
  for (final line in playlist.split('\n')) {
    if (!line.startsWith('#EXT-X-MEDIA:')) continue;
    final data = hlsAttributes(line);
    if (data['TYPE'] != 'SUBTITLES' || data['URI'] == null) continue;
    final url = master.resolve(data['URI']!);
    if (url.scheme == 'https') {
      result.add(
        StreamSubtitle(
          url: url,
          label: data['NAME'] ?? data['LANGUAGE'] ?? 'Subtitles',
          language: data['LANGUAGE'] ?? '',
        ),
      );
    }
  }
  return result;
}

class StreamResolutionException implements Exception {
  const StreamResolutionException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class StreamResolver {
  Future<ResolvedStream> resolve(Uri entryUrl);
  Future<void> dispose();
}

/// Never accept a blob locator, HTML response, or arbitrary local destination.
bool isUsableHlsCandidate(Uri url, String playlist) {
  if (url.scheme != 'https' || url.userInfo.isNotEmpty || url.host.isEmpty) {
    return false;
  }
  final host = url.host.toLowerCase();
  if (host == 'localhost' ||
      host.endsWith('.local') ||
      host.contains(':') ||
      RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) {
    return false;
  }
  final body = playlist.trimLeft();
  return body.startsWith('#EXTM3U') &&
      (body.contains('#EXT-X-STREAM-INF') || body.contains('#EXTINF'));
}

/// Start with a conservative AVC rendition when a master advertises one.
/// This avoids choosing a 4K/HEVC source on devices without that decoder.
Uri preferredNativeHlsUrl(Uri master, String playlist) {
  if (playlist.contains('#EXT-X-MEDIA:')) return master;
  final variants =
      <({Uri url, int height, int bandwidth, bool avc, bool unspecified})>[];
  String? attributes;
  for (final line in playlist.split('\n').map((line) => line.trim())) {
    if (line.startsWith('#EXT-X-STREAM-INF:')) {
      attributes = line;
      continue;
    }
    if (attributes == null || line.isEmpty || line.startsWith('#')) continue;
    final resolution = RegExp(r'RESOLUTION=\d+x(\d+)').firstMatch(attributes);
    final codecs =
        RegExp(r'CODECS="([^"]+)"').firstMatch(attributes)?.group(1) ?? '';
    final bandwidth = RegExp(r'BANDWIDTH=(\d+)').firstMatch(attributes);
    final url = master.resolve(line);
    if (url.scheme == 'https') {
      variants.add((
        url: url,
        height: int.tryParse(resolution?.group(1) ?? '') ?? 0,
        bandwidth: int.tryParse(bandwidth?.group(1) ?? '') ?? 0,
        avc: codecs.toLowerCase().contains('avc1'),
        unspecified: codecs.isEmpty,
      ));
    }
    attributes = null;
  }
  final compatible =
      variants
          .where(
            (variant) =>
                (variant.avc || variant.unspecified) &&
                variant.height > 0 &&
                variant.height <= 720,
          )
          .toList()
        ..sort((a, b) => b.bandwidth.compareTo(a.bandwidth));
  return compatible.isEmpty ? master : compatible.first.url;
}

Uri playbackEntryUrl({
  required String imdbId,
  required bool isWeb,
  String? contentType,
}) {
  final cleanImdbId = imdbId.trim();
  if (isWeb) {
    final embedType = isTvPlaybackContent(contentType) ? 'tv' : 'movie';
    return Uri.https('streamimdb.ru', '/embed/$embedType/$cleanImdbId');
  }

  return Uri.https('www.playimdb.com', '/title/$cleanImdbId/');
}

List<Uri> playbackFallbackUrls({
  required String imdbId,
  int? tmdbId,
  String? contentType,
  int season = 1,
  int episode = 1,
}) {
  final cleanImdbId = imdbId.trim();
  if (cleanImdbId.isEmpty) return const [];
  final safeSeason = season < 1 ? 1 : season;
  final safeEpisode = episode < 1 ? 1 : episode;

  if (isTvPlaybackContent(contentType)) {
    return [
      Uri.https('vsembed.ru', '/embed/tv', {
        'imdb': cleanImdbId,
        'season': '$safeSeason',
        'episode': '$safeEpisode',
      }),
    ];
  }

  return [
    Uri.https('vsembed.ru', '/embed/movie', {'imdb': cleanImdbId}),
  ];
}

Uri cinesrcPlaybackUrl({
  required int tmdbId,
  String? contentType,
  int season = 1,
  int episode = 1,
}) {
  final safeSeason = season < 1 ? 1 : season;
  final safeEpisode = episode < 1 ? 1 : episode;

  if (isTvPlaybackContent(contentType)) {
    return Uri.https('cinesrc.st', '/embed/tv/$tmdbId', {
      's': '$safeSeason',
      'e': '$safeEpisode',
    });
  }

  return Uri.https('cinesrc.st', '/embed/movie/$tmdbId');
}

Uri compactWebPlaybackLaunchUrl({
  required Uri primaryUrl,
  required List<Uri> fallbackUrls,
}) {
  return playbackLaunchUrls(
    primaryUrl: primaryUrl,
    fallbackUrls: fallbackUrls,
  ).first;
}

List<Uri> playbackLaunchUrls({
  required Uri primaryUrl,
  required List<Uri> fallbackUrls,
}) {
  final urls = <Uri>[];
  final seen = <String>{};
  for (final url in [primaryUrl, ...fallbackUrls]) {
    if (seen.add(url.toString())) urls.add(url);
  }
  return urls;
}

typedef PlaybackUrlStatusChecker = Future<int?> Function(Uri url);
typedef PlaybackUrlResponseBodyChecker = Future<String?> Function(Uri url);

Future<Uri?> firstNon404PlaybackLaunchUrl({
  required List<Uri> urls,
  required PlaybackUrlStatusChecker statusCodeForUrl,
  PlaybackUrlResponseBodyChecker? responseBodyForUrl,
}) async {
  for (final url in urls) {
    final statusCode = await statusCodeForUrl(url);
    if (statusCode == 404) continue;

    final responseBody = responseBodyForUrl == null
        ? null
        : await responseBodyForUrl(url);
    if (!playbackResponseBodyLooksUnavailable(responseBody)) {
      return url;
    }
  }

  return null;
}

bool playbackResponseBodyLooksUnavailable(String? body) {
  if (body == null || body.trim().isEmpty) return false;

  final normalized = body.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized.contains('media unavailable at the moment') ||
      normalized.contains('media is unavailable at the moment') ||
      normalized.contains('this media unavailable') ||
      normalized.contains('content not found') ||
      normalized.contains('404 - not found') ||
      normalized.contains('target url returned error 404');
}

bool isTvPlaybackContent(String? contentType) {
  final normalized = contentType?.trim().toLowerCase();
  return normalized == 'tv' ||
      normalized == 'tv show' ||
      normalized == 'series';
}

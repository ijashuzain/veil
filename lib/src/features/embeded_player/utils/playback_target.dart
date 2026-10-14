import 'package:veil/src/features/detail/utils/playback_entry_url.dart';
import 'package:veil/src/shared/models/playback_request.dart';

class PlaybackTarget {
  const PlaybackTarget({
    required this.url,
    this.fallbackUrls = const [],
    this.forceEmbedded = false,
    this.loadAsPage = false,
    this.externalOnWeb = false,
    this.nativePlayback = false,
  });

  final Uri url;
  final List<Uri> fallbackUrls;
  final bool forceEmbedded;
  final bool loadAsPage;
  final bool externalOnWeb;
  final bool nativePlayback;
}

PlaybackTarget? playbackTargetFor(PlaybackRequest request) {
  final item = request.item;

  switch (request.server) {
    case PlaybackServer.one:
      final url = vidsrcPlaybackUrl(
        tmdbId: item.remoteId,
        imdbId: item.imdbId,
        contentType: item.type,
        season: request.safeSeason,
        episode: request.safeEpisode,
      );
      if (url == null) return null;
      return PlaybackTarget(url: url, forceEmbedded: true, loadAsPage: true);
    case PlaybackServer.two:
      final url = cinejoyPlaybackUrl(
        tmdbId: item.remoteId,
        contentType: item.type,
        season: request.safeSeason,
        episode: request.safeEpisode,
      );
      if (url == null) return null;
      return PlaybackTarget(url: url, loadAsPage: true, externalOnWeb: true);
    case PlaybackServer.three:
      final tmdbId = item.remoteId;
      if (tmdbId == null || tmdbId <= 0) return null;
      return PlaybackTarget(
        url: cinesrcPlaybackUrl(
          tmdbId: tmdbId,
          contentType: item.type,
          season: request.safeSeason,
          episode: request.safeEpisode,
        ),
        forceEmbedded: true,
      );
    case PlaybackServer.four:
      final url = vidlinkPlaybackUrl(
        tmdbId: item.remoteId,
        contentType: item.type,
        season: request.safeSeason,
        episode: request.safeEpisode,
      );
      if (url == null) return null;
      return PlaybackTarget(url: url, forceEmbedded: true, loadAsPage: true);
    case PlaybackServer.five:
    case PlaybackServer.six:
      final tmdbId = item.remoteId;
      if (tmdbId == null || tmdbId <= 0) return null;
      return PlaybackTarget(
        url: cinesrcPlaybackUrl(
          tmdbId: tmdbId,
          contentType: item.type,
          season: request.safeSeason,
          episode: request.safeEpisode,
        ),
        forceEmbedded: true,
        loadAsPage: true,
        nativePlayback: true,
      );
  }
}

import 'package:veil/src/shared/models/content_item.dart';

enum PlaybackServer { one, two, three, four, five, six }

class PlaybackRequest {
  const PlaybackRequest({
    required this.item,
    required this.server,
    this.season = 1,
    this.episode = 1,
    this.startPosition = Duration.zero,
  });

  final ContentItem item;
  final PlaybackServer server;
  final int season;
  final int episode;
  final Duration startPosition;

  int get safeSeason => season < 1 ? 1 : season;
  int get safeEpisode => episode < 1 ? 1 : episode;
}

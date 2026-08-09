import 'package:flutter/material.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/models/playback_request.dart';

class PlaybackHistoryEntry {
  const PlaybackHistoryEntry({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.subtitle,
    required this.year,
    required this.genre,
    required this.type,
    required this.rating,
    required this.description,
    required this.runtime,
    required this.server,
    required this.season,
    required this.episode,
    required this.startedAt,
    this.imdbId,
    this.posterUrl,
    this.backdropUrl,
  }) : assert(tmdbId > 0);

  factory PlaybackHistoryEntry.fromRequest(
    PlaybackRequest request,
    DateTime startedAt,
  ) {
    final item = request.item;
    final tmdbId = item.remoteId;
    if (tmdbId == null || tmdbId <= 0) {
      throw ArgumentError.value(tmdbId, 'request.item.remoteId');
    }
    return PlaybackHistoryEntry(
      tmdbId: tmdbId,
      imdbId: item.imdbId,
      mediaType: item.mediaType,
      title: item.title,
      subtitle: item.subtitle,
      year: item.year,
      genre: item.genre,
      type: item.type,
      rating: item.rating,
      posterUrl: item.posterUrl,
      backdropUrl: item.backdropUrl,
      description: item.description,
      runtime: item.runtime,
      server: request.server,
      season: request.safeSeason,
      episode: request.safeEpisode,
      startedAt: startedAt,
    );
  }

  factory PlaybackHistoryEntry.fromJson(Map<String, dynamic> json) {
    final tmdbId = _intValue(json['tmdbId']);
    final title = _stringValue(json['title']).trim();
    final server = _serverValue(json['server']);
    final startedAt = DateTime.tryParse(_stringValue(json['startedAt']));
    if (tmdbId == null ||
        tmdbId <= 0 ||
        title.isEmpty ||
        server == null ||
        startedAt == null) {
      throw const FormatException('Invalid playback history entry.');
    }

    final mediaType = _stringValue(json['mediaType']);
    final type = _stringValue(json['type']);
    final parsedSeason = _intValue(json['season']) ?? 1;
    final parsedEpisode = _intValue(json['episode']) ?? 1;
    return PlaybackHistoryEntry(
      tmdbId: tmdbId,
      imdbId: _nullableStringValue(json['imdbId']),
      mediaType: mediaType,
      title: title,
      subtitle: _stringValue(json['subtitle']),
      year: _intValue(json['year']) ?? 0,
      genre: _stringValue(json['genre']),
      type: type.isEmpty ? (mediaType == 'tv' ? 'TV Show' : 'Movie') : type,
      rating: _doubleValue(json['rating']) ?? 0,
      posterUrl: _nullableStringValue(json['posterUrl']),
      backdropUrl: _nullableStringValue(json['backdropUrl']),
      description: _stringValue(json['description']),
      runtime: _stringValue(json['runtime']),
      server: server,
      season: parsedSeason < 1 ? 1 : parsedSeason,
      episode: parsedEpisode < 1 ? 1 : parsedEpisode,
      startedAt: startedAt,
    );
  }

  final int tmdbId;
  final String? imdbId;
  final String mediaType;
  final String title;
  final String subtitle;
  final int year;
  final String genre;
  final String type;
  final double rating;
  final String? posterUrl;
  final String? backdropUrl;
  final String description;
  final String runtime;
  final PlaybackServer server;
  final int season;
  final int episode;
  final DateTime startedAt;

  String get entryKey =>
      '${mediaType.isEmpty ? type.toLowerCase() : mediaType}:'
      '$tmdbId:${server.name}:$season:$episode';

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': tmdbId,
      'imdbId': imdbId,
      'mediaType': mediaType,
      'title': title,
      'subtitle': subtitle,
      'year': year,
      'genre': genre,
      'type': type,
      'rating': rating,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'description': description,
      'runtime': runtime,
      'server': server.name,
      'season': season,
      'episode': episode,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  ContentItem toContentItem() {
    final isTv =
        mediaType.toLowerCase() == 'tv' ||
        type.toLowerCase().contains('tv') ||
        type.toLowerCase().contains('series');
    final identityType = mediaType.isEmpty
        ? (isTv ? 'tv' : 'movie')
        : mediaType;
    return ContentItem(
      id: '$identityType-$tmdbId',
      remoteId: tmdbId,
      imdbId: imdbId,
      mediaType: mediaType,
      title: title,
      subtitle: subtitle,
      year: year,
      genre: genre,
      type: type,
      rating: rating,
      palette: const [Color(0xFF1B1B1D), Color(0xFF8B1018), Color(0xFF050505)],
      glyph: isTv ? Icons.live_tv_rounded : Icons.movie_rounded,
      description: description,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      runtime: runtime,
    );
  }

  PlaybackRequest toRequest() {
    return PlaybackRequest(
      item: toContentItem(),
      server: server,
      season: season,
      episode: episode,
    );
  }
}

String _stringValue(Object? value) => value is String ? value : '';

String? _nullableStringValue(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value;
}

int? _intValue(Object? value) => value is num ? value.toInt() : null;

double? _doubleValue(Object? value) => value is num ? value.toDouble() : null;

PlaybackServer? _serverValue(Object? value) {
  if (value is! String) return null;
  for (final server in PlaybackServer.values) {
    if (server.name == value) return server;
  }
  return null;
}

import 'package:flutter/material.dart';

class ContentItem {
  const ContentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.year,
    required this.genre,
    required this.type,
    required this.rating,
    required this.palette,
    required this.glyph,
    required this.description,
    this.remoteId,
    this.mediaType = '',
    this.imdbId,
    this.posterUrl,
    this.backdropUrl,
    this.trailerKey,
    this.runtime = '2h 12m',
    this.progress = 0,
    this.progressLabel = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final int year;
  final String genre;
  final String type;
  final double rating;
  final List<Color> palette;
  final IconData glyph;
  final String description;
  final int? remoteId;
  final String mediaType;
  final String? imdbId;
  final String? posterUrl;
  final String? backdropUrl;
  final String? trailerKey;
  final String runtime;
  final double progress;
  final String progressLabel;

  String get metadata => '$type · $year · $genre';

  ContentItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    int? year,
    String? genre,
    String? type,
    double? rating,
    List<Color>? palette,
    IconData? glyph,
    String? description,
    int? remoteId,
    String? mediaType,
    String? imdbId,
    String? posterUrl,
    String? backdropUrl,
    String? trailerKey,
    String? runtime,
    double? progress,
    String? progressLabel,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      palette: palette ?? this.palette,
      glyph: glyph ?? this.glyph,
      description: description ?? this.description,
      remoteId: remoteId ?? this.remoteId,
      mediaType: mediaType ?? this.mediaType,
      imdbId: imdbId ?? this.imdbId,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      trailerKey: trailerKey ?? this.trailerKey,
      runtime: runtime ?? this.runtime,
      progress: progress ?? this.progress,
      progressLabel: progressLabel ?? this.progressLabel,
    );
  }
}

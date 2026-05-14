import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'tmdb_media.freezed.dart';
part 'tmdb_media.g.dart';

@freezed
abstract class TmdbMedia with _$TmdbMedia {
  const TmdbMedia._();

  const factory TmdbMedia({
    @Default(0) int id,
    @JsonKey(name: 'media_type', readValue: _readMediaType)
    @Default('movie')
    String mediaType,
    @JsonKey(name: 'imdb_id') String? imdbId,
    @JsonKey(readValue: _readTitle) @Default('Untitled') String title,
    @Default('') String overview,
    @JsonKey(name: 'poster_path') String? posterPath,
    @JsonKey(name: 'backdrop_path') String? backdropPath,
    @JsonKey(name: 'release_date', readValue: _readReleaseDate)
    @Default('')
    String releaseDate,
    @JsonKey(name: 'vote_average') @Default(0) double voteAverage,
    @JsonKey(name: 'genre_ids') @Default([]) List<int> genreIds,
  }) = _TmdbMedia;

  factory TmdbMedia.fromJson(Map<String, dynamic> json) =>
      _$TmdbMediaFromJson(json);

  String? get posterUrl => _imageUrl('w500', posterPath);

  String? get backdropUrl => _imageUrl('w780', backdropPath ?? posterPath);

  int get releaseYear {
    if (releaseDate.length < 4) return 0;
    return int.tryParse(releaseDate.substring(0, 4)) ?? 0;
  }

  ContentItem toContentItem({Map<int, String> genreLookup = const {}}) {
    final genres = genreIds
        .map((id) => genreLookup[id])
        .whereType<String>()
        .take(2)
        .toList();
    final normalizedMediaType = mediaType == 'tv' ? 'tv' : 'movie';

    return ContentItem(
      id: '$normalizedMediaType-$id',
      remoteId: id,
      mediaType: normalizedMediaType,
      imdbId: imdbId,
      title: title,
      subtitle: normalizedMediaType == 'tv' ? 'Series' : 'Movie',
      year: releaseYear == 0 ? DateTime.now().year : releaseYear,
      genre: genres.isEmpty
          ? _fallbackGenre(normalizedMediaType)
          : genres.join(' / '),
      type: normalizedMediaType == 'tv' ? 'TV Show' : 'Movie',
      rating: double.parse(voteAverage.toStringAsFixed(1)),
      palette: _paletteFor(id),
      glyph: normalizedMediaType == 'tv'
          ? Icons.live_tv_rounded
          : Icons.movie_filter_rounded,
      description: overview.isEmpty
          ? 'Explore trailers, cast, reviews, and release details from TMDB.'
          : overview,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
    );
  }
}

Object? _readTitle(Map<dynamic, dynamic> json, String key) {
  return json['title'] ??
      json['name'] ??
      json['original_title'] ??
      json['original_name'] ??
      'Untitled';
}

Object? _readMediaType(Map<dynamic, dynamic> json, String key) {
  final mediaType = json['media_type'];
  if (mediaType is String && mediaType.isNotEmpty) return mediaType;
  if (json.containsKey('first_air_date') || json.containsKey('name')) {
    return 'tv';
  }
  return 'movie';
}

Object? _readReleaseDate(Map<dynamic, dynamic> json, String key) {
  return json['release_date'] ?? json['first_air_date'] ?? '';
}

String? _imageUrl(String size, String? path) {
  if (path == null || path.isEmpty) return null;
  return 'https://image.tmdb.org/t/p/$size$path';
}

String _fallbackGenre(String mediaType) {
  return mediaType == 'tv' ? 'Drama / Series' : 'Movie / Cinema';
}

List<Color> _paletteFor(int id) {
  const palettes = [
    [Color(0xFF1A0D2E), Color(0xFF4A1A5E), Color(0xFF7C2D12)],
    [Color(0xFF3A1A04), Color(0xFF8B3A0B), Color(0xFFD97706)],
    [Color(0xFF0A1A2E), Color(0xFF1E3A5F), Color(0xFF3A5A8A)],
    [Color(0xFF3A0A5E), Color(0xFFC2185B), Color(0xFFFBBF24)],
    [Color(0xFF0A3A3A), Color(0xFF0E7A7A), Color(0xFFFDE047)],
  ];
  return palettes[id.abs() % palettes.length];
}

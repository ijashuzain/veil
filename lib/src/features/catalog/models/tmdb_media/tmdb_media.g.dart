// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmdbMedia _$TmdbMediaFromJson(Map<String, dynamic> json) => _TmdbMedia(
  id: (json['id'] as num?)?.toInt() ?? 0,
  mediaType: _readMediaType(json, 'media_type') as String? ?? 'movie',
  imdbId: json['imdb_id'] as String?,
  title: _readTitle(json, 'title') as String? ?? 'Untitled',
  overview: json['overview'] as String? ?? '',
  posterPath: json['poster_path'] as String?,
  backdropPath: json['backdrop_path'] as String?,
  releaseDate: _readReleaseDate(json, 'release_date') as String? ?? '',
  voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0,
  genreIds:
      (json['genre_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
);

Map<String, dynamic> _$TmdbMediaToJson(_TmdbMedia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'media_type': instance.mediaType,
      'imdb_id': instance.imdbId,
      'title': instance.title,
      'overview': instance.overview,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'release_date': instance.releaseDate,
      'vote_average': instance.voteAverage,
      'genre_ids': instance.genreIds,
    };

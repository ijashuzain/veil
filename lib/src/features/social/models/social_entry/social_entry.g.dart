// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SocialEntry _$SocialEntryFromJson(Map<String, dynamic> json) => _SocialEntry(
  id: json['id'] as String,
  userId: json['userId'] as String? ?? 'local-user',
  tmdbId: (json['tmdbId'] as num?)?.toInt(),
  imdbId: json['imdbId'] as String?,
  mediaType: json['mediaType'] as String? ?? 'movie',
  title: json['title'] as String,
  subtitle: json['subtitle'] as String? ?? '',
  year: (json['year'] as num?)?.toInt() ?? 0,
  genre: json['genre'] as String? ?? '',
  type: json['type'] as String? ?? 'Movie',
  tmdbRating: (json['tmdbRating'] as num?)?.toDouble() ?? 0,
  posterUrl: json['posterUrl'] as String?,
  backdropUrl: json['backdropUrl'] as String?,
  description: json['description'] as String? ?? '',
  rating: (json['rating'] as num?)?.toDouble() ?? 0,
  review: json['review'] as String? ?? '',
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  watchedOn: json['watchedOn'] == null
      ? null
      : DateTime.parse(json['watchedOn'] as String),
  isFavorite: json['isFavorite'] as bool? ?? false,
  inWatchlist: json['inWatchlist'] as bool? ?? false,
  liked: json['liked'] as bool? ?? false,
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
  authorDisplayName: json['authorDisplayName'] as String? ?? '',
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$SocialEntryToJson(_SocialEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'tmdbId': instance.tmdbId,
      'imdbId': instance.imdbId,
      'mediaType': instance.mediaType,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'year': instance.year,
      'genre': instance.genre,
      'type': instance.type,
      'tmdbRating': instance.tmdbRating,
      'posterUrl': instance.posterUrl,
      'backdropUrl': instance.backdropUrl,
      'description': instance.description,
      'rating': instance.rating,
      'review': instance.review,
      'tags': instance.tags,
      'watchedOn': instance.watchedOn?.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'inWatchlist': instance.inWatchlist,
      'liked': instance.liked,
      'likeCount': instance.likeCount,
      'commentCount': instance.commentCount,
      'authorDisplayName': instance.authorDisplayName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

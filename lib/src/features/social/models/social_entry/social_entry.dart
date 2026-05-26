import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'social_entry.freezed.dart';
part 'social_entry.g.dart';

@freezed
abstract class SocialEntry with _$SocialEntry {
  const SocialEntry._();

  const factory SocialEntry({
    required String id,
    @Default('local-user') String userId,
    int? tmdbId,
    String? imdbId,
    @Default('movie') String mediaType,
    required String title,
    @Default('') String subtitle,
    @Default(0) int year,
    @Default('') String genre,
    @Default('Movie') String type,
    @Default(0) double tmdbRating,
    String? posterUrl,
    String? backdropUrl,
    @Default('') String description,
    @Default(0) double rating,
    @Default('') String review,
    @Default([]) List<String> tags,
    DateTime? watchedOn,
    @Default(false) bool isFavorite,
    @Default(false) bool inWatchlist,
    @Default(false) bool liked,
    @Default(0) int likeCount,
    @Default(false) bool helpful,
    @Default(0) int helpfulCount,
    @Default(0) int commentCount,
    @Default('') String authorDisplayName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SocialEntry;

  factory SocialEntry.fromJson(Map<String, dynamic> json) =>
      _$SocialEntryFromJson(json);

  factory SocialEntry.fromContentItem(
    ContentItem item, {
    String userId = 'local-user',
    double rating = 0,
    String review = '',
    List<String> tags = const [],
    DateTime? watchedOn,
    bool isFavorite = false,
    bool inWatchlist = false,
  }) {
    final now = DateTime.now();
    final mediaType = item.mediaType.isEmpty
        ? item.type.toLowerCase().contains('tv')
              ? 'tv'
              : 'movie'
        : item.mediaType;
    final tmdbId = item.remoteId;
    return SocialEntry(
      id: _entryId(mediaType: mediaType, tmdbId: tmdbId, fallbackId: item.id),
      userId: userId,
      tmdbId: tmdbId,
      imdbId: item.imdbId,
      mediaType: mediaType,
      title: item.title,
      subtitle: item.subtitle,
      year: item.year,
      genre: item.genre,
      type: item.type,
      tmdbRating: item.rating,
      posterUrl: item.posterUrl,
      backdropUrl: item.backdropUrl,
      description: item.description,
      rating: rating,
      review: review,
      tags: tags,
      watchedOn: watchedOn,
      isFavorite: isFavorite,
      inWatchlist: inWatchlist,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory SocialEntry.fromSupabaseJson(Map<String, dynamic> json) {
    return SocialEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'local-user',
      tmdbId: json['tmdb_id'] as int?,
      imdbId: json['imdb_id'] as String?,
      mediaType: json['media_type'] as String? ?? 'movie',
      title: json['title'] as String? ?? 'Untitled',
      subtitle: json['subtitle'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      genre: json['genre'] as String? ?? '',
      type: json['type'] as String? ?? 'Movie',
      tmdbRating: (json['tmdb_rating'] as num?)?.toDouble() ?? 0,
      posterUrl: json['poster_url'] as String?,
      backdropUrl: json['backdrop_url'] as String?,
      description: json['description'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      review: json['review'] as String? ?? '',
      tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
      watchedOn: _parseDate(json['watched_on']),
      isFavorite: json['is_favorite'] == true,
      inWatchlist: json['in_watchlist'] == true,
      liked: json['liked'] == true,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      helpful: json['helpful'] == true,
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      authorDisplayName: json['author_display_name'] as String? ?? '',
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabaseJson({required String userId}) {
    return {
      'id': id,
      'user_id': userId,
      'tmdb_id': tmdbId,
      'imdb_id': imdbId,
      'media_type': mediaType,
      'title': title,
      'subtitle': subtitle,
      'year': year,
      'genre': genre,
      'type': type,
      'tmdb_rating': tmdbRating,
      'poster_url': posterUrl,
      'backdrop_url': backdropUrl,
      'description': description,
      'rating': rating,
      'review': review,
      'tags': tags,
      'watched_on': watchedOn?.toIso8601String(),
      'is_favorite': isFavorite,
      'in_watchlist': inWatchlist,
      'liked': liked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ContentItem toContentItem() {
    return ContentItem(
      id: id,
      remoteId: tmdbId,
      imdbId: imdbId,
      mediaType: mediaType,
      title: title,
      subtitle: subtitle,
      year: year,
      genre: genre,
      type: type,
      rating: tmdbRating,
      palette: const [Color(0xFF1B1B1D), Color(0xFF8B1018), Color(0xFF050505)],
      glyph: mediaType == 'tv'
          ? Icons.live_tv_rounded
          : Icons.movie_filter_rounded,
      description: description,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
    );
  }

  bool get hasSpoilers {
    return tags.any((tag) => tag.toLowerCase().trim() == 'spoiler');
  }
}

String _entryId({
  required String mediaType,
  int? tmdbId,
  required String fallbackId,
}) {
  return '${mediaType}_${tmdbId ?? fallbackId}';
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

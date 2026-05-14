import 'package:flutter/material.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/shared/models/content_item.dart';

class MovieSuggestion {
  const MovieSuggestion({
    required this.id,
    required this.senderId,
    required this.recipientId,
    this.senderDisplayName = '',
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory MovieSuggestion.create({
    required String senderId,
    required String recipientId,
    required String senderDisplayName,
    required ContentItem content,
  }) {
    final now = DateTime.now();
    return MovieSuggestion(
      id: '${senderId}_${recipientId}_${content.id}_${now.microsecondsSinceEpoch}',
      senderId: senderId,
      recipientId: recipientId,
      senderDisplayName: senderDisplayName,
      content: content,
      createdAt: now,
    );
  }

  factory MovieSuggestion.fromJson(Map<String, dynamic> json) {
    return MovieSuggestion(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      recipientId: json['recipient_id'] as String? ?? '',
      senderDisplayName: json['sender_display_name'] as String? ?? '',
      content: _contentFromJson(json),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      readAt: _parseDate(json['read_at']),
    );
  }

  factory MovieSuggestion.fromSupabaseJson(Map<String, dynamic> json) {
    return MovieSuggestion.fromJson(json);
  }

  final String id;
  final String senderId;
  final String recipientId;
  final String senderDisplayName;
  final ContentItem content;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'sender_display_name': senderDisplayName,
      ..._contentToJson(content),
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsertJson() {
    return {
      'sender_id': senderId,
      'recipient_id': recipientId,
      'sender_display_name': senderDisplayName,
      ..._contentToJson(content),
    };
  }

  MovieSuggestion copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? senderDisplayName,
    ContentItem? content,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return MovieSuggestion(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

Map<String, dynamic> _contentToJson(ContentItem item) {
  final entry = SocialEntry.fromContentItem(item);
  return {
    'content_id': item.id,
    'tmdb_id': item.remoteId,
    'imdb_id': item.imdbId,
    'media_type': entry.mediaType,
    'title': item.title,
    'subtitle': item.subtitle,
    'year': item.year,
    'genre': item.genre,
    'type': item.type,
    'tmdb_rating': item.rating,
    'poster_url': item.posterUrl,
    'backdrop_url': item.backdropUrl,
    'description': item.description,
  };
}

ContentItem _contentFromJson(Map<String, dynamic> json) {
  final mediaType = json['media_type'] as String? ?? 'movie';
  final id =
      json['content_id'] as String? ??
      '${mediaType}_${json['tmdb_id'] ?? json['title'] ?? 'suggestion'}';
  return ContentItem(
    id: id,
    remoteId: (json['tmdb_id'] as num?)?.toInt(),
    imdbId: json['imdb_id'] as String?,
    mediaType: mediaType,
    title: json['title'] as String? ?? 'Untitled',
    subtitle: json['subtitle'] as String? ?? '',
    year: (json['year'] as num?)?.toInt() ?? 0,
    genre: json['genre'] as String? ?? '',
    type: json['type'] as String? ?? 'Movie',
    rating: (json['tmdb_rating'] as num?)?.toDouble() ?? 0,
    palette: const [Color(0xFF1B1B1D), Color(0xFF8B1018), Color(0xFF050505)],
    glyph: mediaType == 'tv'
        ? Icons.live_tv_rounded
        : Icons.movie_filter_rounded,
    description: json['description'] as String? ?? '',
    posterUrl: json['poster_url'] as String?,
    backdropUrl: json['backdrop_url'] as String?,
  );
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

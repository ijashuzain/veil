import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/catalog/models/curated_collection.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'curated_collection_repository.g.dart';

@riverpod
CuratedCollectionRepository curatedCollectionRepository(Ref ref) {
  return CuratedCollectionRepository(
    api: ref.watch(apiProvider),
    tmdbRepository: ref.watch(tmdbRepositoryProvider),
  );
}

class CuratedCollectionRepository {
  CuratedCollectionRepository({
    required this.api,
    required this.tmdbRepository,
  });

  static const _host = 'lists.shegu.st';
  static const _palette = [VeilColors.bg2, VeilColors.bg4];

  final Api api;
  final TmdbRepository tmdbRepository;
  final Map<(String, int), List<ContentItem>> _itemCache = {};

  Future<List<CuratedCollection>> collections() async {
    final response = await api.general.getUri<Object?>(
      Uri.https(_host, '/joy'),
    );
    final root = _map(response.data);
    final rows = root?['collections'];
    if (rows is! List) return const [];

    return List.unmodifiable(
      rows.map(_collectionFromJson).whereType<CuratedCollection>(),
    );
  }

  Future<List<ContentItem>> items(String collectionId, {int limit = 12}) async {
    final cleanId = collectionId.trim();
    if (cleanId.isEmpty) {
      throw ArgumentError.value(
        collectionId,
        'collectionId',
        'Cannot be empty.',
      );
    }
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive.');
    }

    final cacheKey = (cleanId, limit);
    final cached = _itemCache[cacheKey];
    if (cached != null) return cached;

    final response = await api.general.getUri<Object?>(
      Uri(
        scheme: 'https',
        host: _host,
        pathSegments: ['joy', cleanId],
        queryParameters: {'limit': '$limit'},
      ),
    );
    final root = _map(response.data);
    final rows = root?['items'];
    if (rows is! List) {
      const empty = <ContentItem>[];
      _itemCache[cacheKey] = empty;
      return empty;
    }

    final parsed = rows.map(_itemFromJson).whereType<ContentItem>().toList();
    final visible = await Future.wait<ContentItem?>(
      parsed.map((item) async {
        if (await tmdbRepository.shouldHideForCurrentUser(item)) return null;
        return item;
      }),
    );
    final result = List<ContentItem>.unmodifiable(
      visible.whereType<ContentItem>(),
    );
    _itemCache[cacheKey] = result;
    return result;
  }

  CuratedCollection? _collectionFromJson(Object? value) {
    final json = _map(value);
    if (json == null) return null;

    final id = _string(json['id']);
    final title = _string(json['title']);
    if (id.isEmpty || title.isEmpty) return null;

    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags.map(_string).where((tag) => tag.isNotEmpty).toList()
        : const <String>[];
    return CuratedCollection(
      id: id,
      title: title,
      description: _string(json['description']),
      tags: List.unmodifiable(tags),
    );
  }

  ContentItem? _itemFromJson(Object? value) {
    final json = _map(value);
    if (json == null) return null;

    final ids = _map(json['ids']);
    final tmdbId = _positiveInt(ids?['tmdb']);
    final title = _string(json['title']);
    final mediaType = _mediaType(json['type']);
    if (tmdbId == null || title.isEmpty || mediaType == null) return null;

    final poster = _string(json['poster']);
    final imdbId = _string(ids?['imdb']);
    final isTv = mediaType == 'tv';
    return ContentItem(
      id: '$mediaType-$tmdbId',
      remoteId: tmdbId,
      mediaType: mediaType,
      imdbId: imdbId.isEmpty ? null : imdbId,
      title: title,
      subtitle: isTv ? 'TV Show' : 'Movie',
      year: _nonNegativeInt(json['year']),
      genre: 'Curated',
      type: isTv ? 'TV Show' : 'Movie',
      rating: _score(json['score']),
      palette: _palette,
      glyph: isTv ? Icons.live_tv_rounded : Icons.movie_rounded,
      description: _string(json['description']),
      posterUrl: poster.isEmpty
          ? null
          : AppEnvironment.resolveTmdbImageUrl(poster),
    );
  }

  Map<String, Object?>? _map(Object? value) {
    if (value is! Map) return null;
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is String) result[key] = entry.value;
    }
    return result;
  }

  String _string(Object? value) => value is String ? value.trim() : '';

  int? _positiveInt(Object? value) {
    if (value is! num || !value.isFinite) return null;
    final integer = value.toInt();
    if (integer <= 0 || integer != value) return null;
    return integer;
  }

  int _nonNegativeInt(Object? value) {
    if (value is! num || !value.isFinite) return 0;
    return value < 0 ? 0 : value.toInt();
  }

  double _score(Object? value) {
    if (value is! num || !value.isFinite) return 0;
    return value.toDouble().clamp(0, 10).toDouble();
  }

  String? _mediaType(Object? value) {
    final normalized = _string(
      value,
    ).toLowerCase().replaceAll(RegExp(r'[_-]+'), ' ');
    return switch (normalized) {
      'movie' || 'film' => 'movie',
      'tv' || 'tv show' || 'tv series' || 'show' || 'series' => 'tv',
      _ => null,
    };
  }
}

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/app/services/api_services/api_service.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/constants/endpoints.dart';
import 'package:veil/src/features/catalog/models/content_detail/content_detail.dart';
import 'package:veil/src/features/catalog/models/tmdb_media/tmdb_media.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'tmdb_repository.g.dart';

@riverpod
TmdbRepository tmdbRepository(Ref ref) {
  return TmdbRepository(
    api: ref.watch(apiProvider),
    readAccessToken: AppEnvironment.tmdbReadAccessToken,
    apiKey: AppEnvironment.tmdbApiKey,
  );
}

class MissingTmdbCredentialsException implements Exception {
  const MissingTmdbCredentialsException();

  @override
  String toString() {
    return 'Missing TMDB credentials. Pass TMDB_READ_ACCESS_TOKEN or TMDB_API_KEY with --dart-define.';
  }
}

class TmdbRepository {
  const TmdbRepository({
    required this.api,
    this.readAccessToken = '',
    this.apiKey = '',
  });

  final Api api;
  final String readAccessToken;
  final String apiKey;

  static const genreLookup = <int, String>{
    12: 'Adventure',
    14: 'Fantasy',
    16: 'Animation',
    18: 'Drama',
    20: 'Action & Adventure',
    27: 'Horror',
    28: 'Action',
    35: 'Comedy',
    36: 'History',
    37: 'Western',
    51: 'Family',
    53: 'Thriller',
    80: 'Crime',
    9648: 'Mystery',
    99: 'Documentary',
    10751: 'Family',
    10752: 'War',
    10759: 'Action & Adventure',
    10762: 'Kids',
    10763: 'News',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Soap',
    10767: 'Talk',
    10768: 'War & Politics',
    878: 'Sci-Fi',
    10402: 'Music',
    10749: 'Romance',
    10770: 'TV Movie',
  };

  bool get hasCredentials => readAccessToken.isNotEmpty || apiKey.isNotEmpty;

  Future<List<ContentItem>> trending() {
    return _getMediaList(Endpoints.trendingAllWeek);
  }

  Future<List<ContentItem>> trendingPage(int page) {
    return _getMediaList(
      Endpoints.trendingAllWeek,
      queryParameters: {'page': page},
    );
  }

  Future<List<ContentItem>> popularMovies() {
    return _getMediaList(Endpoints.moviePopular, mediaType: 'movie');
  }

  Future<List<ContentItem>> nowPlayingMovies() {
    return _getMediaList(Endpoints.movieNowPlaying, mediaType: 'movie');
  }

  Future<List<ContentItem>> upcomingMovies() {
    return _getMediaList(Endpoints.movieUpcoming, mediaType: 'movie');
  }

  Future<List<ContentItem>> topRatedMovies() {
    return _getMediaList(Endpoints.movieTopRated, mediaType: 'movie');
  }

  Future<List<ContentItem>> popularTv() {
    return _getMediaList(Endpoints.tvPopular, mediaType: 'tv');
  }

  Future<List<ContentItem>> topRatedTv() {
    return _getMediaList(Endpoints.tvTopRated, mediaType: 'tv');
  }

  Future<List<ContentItem>> airingTodayTv() {
    return _getMediaList(Endpoints.tvAiringToday, mediaType: 'tv');
  }

  Future<List<ContentItem>> onTheAirTv() {
    return _getMediaList(Endpoints.tvOnTheAir, mediaType: 'tv');
  }

  Future<List<String>> genres() async {
    final detailed = await genresDetailed();
    return detailed.map((genre) => genre.name).toSet().toList();
  }

  Future<List<TmdbGenre>> genresDetailed() async {
    _ensureCredentials();
    final responses = await Future.wait([
      api.general.get<Map<String, dynamic>>(
        Endpoints.genreMovieList,
        queryParameters: _query({'language': 'en-US'}),
        options: _options(),
      ),
      api.general.get<Map<String, dynamic>>(
        Endpoints.genreTvList,
        queryParameters: _query({'language': 'en-US'}),
        options: _options(),
      ),
    ]);
    final genresById = <int, TmdbGenre>{};
    for (final response in responses) {
      final genres = response.data?['genres'];
      if (genres is! List) continue;
      for (final genre in genres.whereType<Map<String, dynamic>>()) {
        final id = genre['id'] as int?;
        final name = genre['name'] as String?;
        if (id != null && name != null && name.trim().isNotEmpty) {
          genresById.putIfAbsent(id, () => TmdbGenre(id: id, name: name));
        }
      }
    }
    return genresById.values.toList();
  }

  Future<List<ContentItem>> discoverMoviesByGenre(int genreId) {
    return _getMediaList(
      Endpoints.discoverMovieByGenre(genreId),
      mediaType: 'movie',
      queryParameters: {'with_genres': genreId, 'sort_by': 'popularity.desc'},
    );
  }

  Future<List<ContentItem>> discoverTvByGenre(int genreId) {
    return _getMediaList(
      Endpoints.discoverTvByGenre(genreId),
      mediaType: 'tv',
      queryParameters: {'with_genres': genreId, 'sort_by': 'popularity.desc'},
    );
  }

  Future<List<ContentItem>> search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(const []);
    return _getMediaList(
      Endpoints.searchMulti,
      queryParameters: {'query': trimmed, 'include_adult': false},
    );
  }

  Future<ContentItem?> resolveMovie({
    int? tmdbId,
    String? imdbId,
    String title = '',
    int year = 0,
  }) async {
    _ensureCredentials();

    if (tmdbId != null) {
      final item = await _tryResolve(
        () =>
            _movieDetailItem(tmdbId, fallbackTitle: title, fallbackYear: year),
      );
      if (item != null) return item;
    }

    final cleanImdbId = imdbId?.trim();
    if (cleanImdbId != null && cleanImdbId.isNotEmpty) {
      final item = await _tryResolve(
        () => _movieFromExternalId(cleanImdbId, title: title, year: year),
      );
      if (item != null) return item;
    }

    final cleanTitle = title.trim();
    if (cleanTitle.isNotEmpty) {
      return _tryResolve(() => _movieFromTitle(cleanTitle, year: year));
    }

    return null;
  }

  Future<List<ContentItem>> sectionPage(
    String section, {
    int page = 1,
    int? genreId,
    double minRating = 0,
  }) {
    final query = <String, dynamic>{'page': page};
    if (genreId != null) query['with_genres'] = genreId;
    if (minRating > 0) query['vote_average.gte'] = minRating * 2;
    return switch (section) {
      'trending' => _getMediaList(
        Endpoints.trendingAllWeek,
        queryParameters: query,
      ),
      'upcoming' => _getMediaList(
        Endpoints.movieUpcoming,
        mediaType: 'movie',
        queryParameters: query,
      ),
      'popular_movies' => _getMediaList(
        genreId == null ? Endpoints.moviePopular : Endpoints.discoverMovie,
        mediaType: 'movie',
        queryParameters: {
          ...query,
          if (genreId != null) 'sort_by': 'popularity.desc',
        },
      ),
      'top_rated_movies' => _getMediaList(
        genreId == null ? Endpoints.movieTopRated : Endpoints.discoverMovie,
        mediaType: 'movie',
        queryParameters: {
          ...query,
          if (genreId != null) 'sort_by': 'vote_average.desc',
        },
      ),
      'top_rated_tv' => _getMediaList(
        genreId == null ? Endpoints.tvTopRated : Endpoints.discoverTv,
        mediaType: 'tv',
        queryParameters: {
          ...query,
          if (genreId != null) 'sort_by': 'vote_average.desc',
        },
      ),
      'airing_today' => _getMediaList(
        Endpoints.tvAiringToday,
        mediaType: 'tv',
        queryParameters: query,
      ),
      _ => _getMediaList(
        Endpoints.discoverMovie,
        mediaType: 'movie',
        queryParameters: {...query, 'sort_by': 'popularity.desc'},
      ),
    };
  }

  Future<ContentDetail> detail(ContentItem item) async {
    final remoteId = item.remoteId;
    if (remoteId == null) return ContentDetail.fallback(item);

    _ensureCredentials();
    final mediaType = item.mediaType == 'tv' ? 'tv' : 'movie';
    final endpoint = mediaType == 'tv'
        ? Endpoints.tvDetail(remoteId)
        : Endpoints.movieDetail(remoteId);
    final response = await api.general.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: _query({
        'append_to_response': mediaType == 'tv'
            ? 'videos,credits,images,recommendations,similar,reviews,watch/providers,external_ids,content_ratings'
            : 'videos,credits,images,recommendations,similar,reviews,watch/providers,external_ids,release_dates',
        'include_image_language': 'en,null',
        'language': 'en-US',
      }),
      options: _options(),
    );

    final data = response.data;
    if (data == null) return ContentDetail.fallback(item);
    return _detailFromJson(item: item, json: data, mediaType: mediaType);
  }

  Future<List<ContentItem>> _getMediaList(
    String endpoint, {
    String? mediaType,
    Map<String, dynamic> queryParameters = const {},
  }) async {
    _ensureCredentials();
    final response = await api.general.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: _query({'language': 'en-US', ...queryParameters}),
      options: _options(),
    );
    final results = response.data?['results'];
    if (results is! List) return const [];

    return results
        .whereType<Map<String, dynamic>>()
        .map((json) {
          final normalized = mediaType == null
              ? json
              : {...json, 'media_type': json['media_type'] ?? mediaType};
          return TmdbMedia.fromJson(
            normalized,
          ).toContentItem(genreLookup: genreLookup);
        })
        .where((item) => item.remoteId != null)
        .toList();
  }

  Future<ContentItem?> _tryResolve(
    Future<ContentItem?> Function() action,
  ) async {
    try {
      return await action();
    } on DioException {
      return null;
    }
  }

  Future<ContentItem?> _movieDetailItem(
    int tmdbId, {
    String title = '',
    int fallbackYear = 0,
    String fallbackTitle = '',
  }) async {
    final fallback = TmdbMedia.fromJson({
      'id': tmdbId,
      'media_type': 'movie',
      'title': fallbackTitle.trim().isEmpty ? title : fallbackTitle,
      if (fallbackYear > 0) 'release_date': '$fallbackYear-01-01',
    }).toContentItem(genreLookup: genreLookup);
    final detailed = await detail(fallback);
    return detailed.item;
  }

  Future<ContentItem?> _movieFromExternalId(
    String imdbId, {
    required String title,
    required int year,
  }) async {
    final response = await api.general.get<Map<String, dynamic>>(
      Endpoints.findByExternalId(imdbId),
      queryParameters: _query({
        'external_source': 'imdb_id',
        'language': 'en-US',
      }),
      options: _options(),
    );
    final results = _movieResults(response.data?['movie_results']);
    final match = _bestMovieMatch(results, title: title, year: year);
    return match?.copyWith(imdbId: imdbId);
  }

  Future<ContentItem?> _movieFromTitle(
    String title, {
    required int year,
  }) async {
    final response = await api.general.get<Map<String, dynamic>>(
      Endpoints.searchMovie,
      queryParameters: _query({
        'query': title,
        'include_adult': false,
        if (year > 0) 'primary_release_year': year,
        'language': 'en-US',
      }),
      options: _options(),
    );
    final results = _movieResults(response.data?['results']);
    return _bestMovieMatch(results, title: title, year: year);
  }

  List<ContentItem> _movieResults(Object? results) {
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => TmdbMedia.fromJson({
            ...json,
            'media_type': 'movie',
          }).toContentItem(genreLookup: genreLookup),
        )
        .where((item) => item.remoteId != null)
        .toList();
  }

  ContentItem? _bestMovieMatch(
    List<ContentItem> results, {
    required String title,
    required int year,
  }) {
    if (results.isEmpty) return null;
    final normalizedTitle = _normalizeTitle(title);
    if (normalizedTitle.isNotEmpty && year > 0) {
      final exact = results.where((item) {
        return item.year == year &&
            _normalizeTitle(item.title) == normalizedTitle;
      }).firstOrNull;
      if (exact != null) return exact;
    }
    if (year > 0) {
      final sameYear = results.where((item) => item.year == year).firstOrNull;
      if (sameYear != null) return sameYear;
    }
    if (normalizedTitle.isNotEmpty) {
      final sameTitle = results.where((item) {
        return _normalizeTitle(item.title) == normalizedTitle;
      }).firstOrNull;
      if (sameTitle != null) return sameTitle;
    }
    return results.first;
  }

  Map<String, dynamic> _query(Map<String, dynamic> values) {
    return {
      ...values,
      if (readAccessToken.isEmpty && apiKey.isNotEmpty) 'api_key': apiKey,
    };
  }

  Options _options() {
    return Options(
      headers: {
        if (readAccessToken.isNotEmpty)
          'Authorization': 'Bearer $readAccessToken',
      },
    );
  }

  void _ensureCredentials() {
    if (!hasCredentials) throw const MissingTmdbCredentialsException();
  }

  ContentDetail _detailFromJson({
    required ContentItem item,
    required Map<String, dynamic> json,
    required String mediaType,
  }) {
    final genres = _genreNames(json['genres']);
    final videos = _videos(json['videos']);
    final primaryTrailer = _primaryTrailer(videos);
    final enriched = item.copyWith(
      title: _string(json['title']) ?? _string(json['name']) ?? item.title,
      subtitle: _string(json['tagline'])?.isNotEmpty ?? false
          ? _string(json['tagline'])
          : item.subtitle,
      year: _releaseYear(json) == 0 ? item.year : _releaseYear(json),
      genre: genres.isEmpty ? item.genre : genres.take(2).join(' / '),
      rating: _double(json['vote_average']) == 0
          ? item.rating
          : double.parse(_double(json['vote_average']).toStringAsFixed(1)),
      imdbId: _imdbId(json) ?? item.imdbId,
      description: _string(json['overview'])?.isNotEmpty ?? false
          ? _string(json['overview'])!
          : item.description,
      runtime: _runtime(json, mediaType) ?? item.runtime,
      posterUrl:
          _imageUrl('w500', _string(json['poster_path'])) ?? item.posterUrl,
      backdropUrl:
          _imageUrl('w780', _string(json['backdrop_path'])) ?? item.backdropUrl,
      trailerKey: primaryTrailer?.key ?? item.trailerKey,
    );

    return ContentDetail(
      item: enriched,
      tagline: _string(json['tagline']) ?? '',
      status: _string(json['status']) ?? '',
      studio: _studio(json, mediaType),
      certification: _certification(json, mediaType),
      homepage: _string(json['homepage']) ?? '',
      originalLanguage: _string(json['original_language']) ?? '',
      spokenLanguages: _spokenLanguages(json['spoken_languages']),
      releaseDate:
          _string(json['release_date']) ??
          _string(json['first_air_date']) ??
          '',
      seasons: _int(json['number_of_seasons']),
      episodes: _int(json['number_of_episodes']),
      videos: videos,
      cast: _cast(json['credits']),
      reviews: _reviews(json['reviews']),
      recommendations: _mediaResults(json['recommendations'], mediaType),
      similar: _mediaResults(json['similar'], mediaType),
      watchProviders: _watchProviders(json['watch/providers']),
      backdropUrls: _backdropUrls(json['images']),
    );
  }

  List<ContentItem> _mediaResults(Object? value, String mediaType) {
    if (value is! Map<String, dynamic>) return const [];
    final results = value['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((json) {
          return TmdbMedia.fromJson({
            ...json,
            'media_type': json['media_type'] ?? mediaType,
          }).toContentItem(genreLookup: genreLookup);
        })
        .where((item) => item.remoteId != null)
        .take(12)
        .toList();
  }

  List<String> _genreNames(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((genre) => _string(genre['name']))
        .whereType<String>()
        .toList();
  }

  List<ContentVideo> _videos(Object? value) {
    if (value is! Map<String, dynamic>) return const [];
    final results = value['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map(
          (video) => ContentVideo(
            key: _string(video['key']) ?? '',
            name: _string(video['name']) ?? 'Video',
            site: _string(video['site']) ?? '',
            type: _string(video['type']) ?? '',
            official: video['official'] == true,
          ),
        )
        .where((video) => video.key.isNotEmpty)
        .take(8)
        .toList();
  }

  ContentVideo? _primaryTrailer(List<ContentVideo> videos) {
    for (final video in videos) {
      if (video.isYouTube && video.official && video.type == 'Trailer') {
        return video;
      }
    }
    for (final video in videos) {
      if (video.isYouTube && video.type == 'Trailer') return video;
    }
    return videos.where((video) => video.isYouTube).firstOrNull;
  }

  List<CastMember> _cast(Object? value) {
    if (value is! Map<String, dynamic>) return const [];
    final cast = value['cast'];
    if (cast is! List) return const [];
    return cast
        .whereType<Map<String, dynamic>>()
        .map(
          (person) => CastMember(
            name: _string(person['name']) ?? '',
            role: _string(person['character']) ?? '',
            profileUrl: _imageUrl('w185', _string(person['profile_path'])),
          ),
        )
        .where((person) => person.name.isNotEmpty)
        .take(12)
        .toList();
  }

  List<ContentReview> _reviews(Object? value) {
    if (value is! Map<String, dynamic>) return const [];
    final results = value['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((review) {
          final details = review['author_details'];
          return ContentReview(
            author: _string(review['author']) ?? 'TMDB user',
            content: _string(review['content']) ?? '',
            rating: details is Map ? _double(details['rating']) : 0,
          );
        })
        .where((review) => review.content.isNotEmpty)
        .take(6)
        .toList();
  }

  List<String> _watchProviders(Object? value) {
    if (value is! Map<String, dynamic>) return const [];
    final results = value['results'];
    if (results is! Map<String, dynamic>) return const [];
    final region = results['US'] ?? results['IN'];
    if (region is! Map<String, dynamic>) return const [];

    final names = <String>{};
    for (final key in ['flatrate', 'free', 'ads', 'rent', 'buy']) {
      final providers = region[key];
      if (providers is List) {
        names.addAll(
          providers
              .whereType<Map<String, dynamic>>()
              .map((provider) => _string(provider['provider_name']))
              .whereType<String>(),
        );
      }
    }
    return names.take(4).toList();
  }

  String? _imdbId(Map<String, dynamic> json) {
    final root = _string(json['imdb_id']);
    if (root != null && root.isNotEmpty) return root;
    final externalIds = json['external_ids'];
    if (externalIds is! Map<String, dynamic>) return null;
    final external = _string(externalIds['imdb_id']);
    if (external == null || external.isEmpty) return null;
    return external;
  }

  List<String> _backdropUrls(Object? value) {
    if (value is! Map<String, dynamic>) return const [];
    final backdrops = value['backdrops'];
    if (backdrops is! List) return const [];
    return backdrops
        .whereType<Map<String, dynamic>>()
        .map((image) => _imageUrl('w780', _string(image['file_path'])))
        .whereType<String>()
        .take(8)
        .toList();
  }

  String _studio(Map<String, dynamic> json, String mediaType) {
    final key = mediaType == 'tv' ? 'networks' : 'production_companies';
    final companies = json[key];
    if (companies is! List || companies.isEmpty) return 'TMDB';
    final first = companies.whereType<Map<String, dynamic>>().firstOrNull;
    return _string(first?['name']) ?? 'TMDB';
  }

  String _certification(Map<String, dynamic> json, String mediaType) {
    final root = mediaType == 'tv'
        ? json['content_ratings']
        : json['release_dates'];
    if (root is! Map<String, dynamic>) return '';
    final results = root['results'];
    if (results is! List) return '';
    final us = results.whereType<Map<String, dynamic>>().firstWhere(
      (entry) => entry['iso_3166_1'] == 'US',
      orElse: () => const {},
    );
    if (mediaType == 'tv') return _string(us['rating']) ?? '';
    final releases = us['release_dates'];
    if (releases is! List) return '';
    for (final release in releases.whereType<Map<String, dynamic>>()) {
      final certification = _string(release['certification']);
      if (certification != null && certification.isNotEmpty) {
        return certification;
      }
    }
    return '';
  }

  String _spokenLanguages(Object? value) {
    if (value is! List) return '';
    return value
        .whereType<Map<String, dynamic>>()
        .map((language) => _string(language['english_name']))
        .whereType<String>()
        .take(3)
        .join(', ');
  }

  int _releaseYear(Map<String, dynamic> json) {
    final date =
        _string(json['release_date']) ?? _string(json['first_air_date']);
    if (date == null || date.length < 4) return 0;
    return int.tryParse(date.substring(0, 4)) ?? 0;
  }

  String? _runtime(Map<String, dynamic> json, String mediaType) {
    if (mediaType == 'movie') return _minutesToRuntime(_int(json['runtime']));
    final episodeRuntime = json['episode_run_time'];
    if (episodeRuntime is List && episodeRuntime.isNotEmpty) {
      return _minutesToRuntime(_int(episodeRuntime.first));
    }
    final seasons = _int(json['number_of_seasons']);
    if (seasons > 0) return '$seasons Season${seasons == 1 ? '' : 's'}';
    return null;
  }

  String? _minutesToRuntime(int minutes) {
    if (minutes <= 0) return null;
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '${remaining}m';
    if (remaining == 0) return '${hours}h';
    return '${hours}h ${remaining}m';
  }

  String? _imageUrl(String size, String? path) {
    if (path == null || path.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/$size$path';
  }

  String? _string(Object? value) => value is String ? value : null;

  int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  double _double(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
  }
}

class TmdbGenre {
  const TmdbGenre({required this.id, required this.name});

  final int id;
  final String name;
}

String _normalizeTitle(String title) {
  return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

import 'package:veil/src/core/config/app_environment.dart';

class Endpoints {
  const Endpoints._();

  static String get tmdbBaseUrl => AppEnvironment.tmdbBaseUrl;

  static String get trendingAllWeek => '$tmdbBaseUrl/trending/all/week';
  static String get configuration => '$tmdbBaseUrl/configuration';
  static String get moviePopular => '$tmdbBaseUrl/movie/popular';
  static String get movieNowPlaying => '$tmdbBaseUrl/movie/now_playing';
  static String get movieTopRated => '$tmdbBaseUrl/movie/top_rated';
  static String get movieUpcoming => '$tmdbBaseUrl/movie/upcoming';
  static String get tvPopular => '$tmdbBaseUrl/tv/popular';
  static String get tvTopRated => '$tmdbBaseUrl/tv/top_rated';
  static String get tvAiringToday => '$tmdbBaseUrl/tv/airing_today';
  static String get tvOnTheAir => '$tmdbBaseUrl/tv/on_the_air';
  static String get searchMulti => '$tmdbBaseUrl/search/multi';
  static String get searchMovie => '$tmdbBaseUrl/search/movie';
  static String get genreMovieList => '$tmdbBaseUrl/genre/movie/list';
  static String get genreTvList => '$tmdbBaseUrl/genre/tv/list';
  static String get discoverMovie => '$tmdbBaseUrl/discover/movie';
  static String get discoverTv => '$tmdbBaseUrl/discover/tv';

  static String movieDetail(int id) => '$tmdbBaseUrl/movie/$id';
  static String tvDetail(int id) => '$tmdbBaseUrl/tv/$id';
  static String findByExternalId(String id) => '$tmdbBaseUrl/find/$id';
  static String movieVideos(int id) => '$tmdbBaseUrl/movie/$id/videos';
  static String movieCredits(int id) => '$tmdbBaseUrl/movie/$id/credits';
  static String discoverMovieByGenre(int genreId) => discoverMovie;
  static String discoverTvByGenre(int genreId) => discoverTv;
}

class Endpoints {
  const Endpoints._();

  static const tmdbBaseUrl = 'https://api.themoviedb.org/3';

  static const trendingAllWeek = '$tmdbBaseUrl/trending/all/week';
  static const configuration = '$tmdbBaseUrl/configuration';
  static const moviePopular = '$tmdbBaseUrl/movie/popular';
  static const movieNowPlaying = '$tmdbBaseUrl/movie/now_playing';
  static const movieTopRated = '$tmdbBaseUrl/movie/top_rated';
  static const movieUpcoming = '$tmdbBaseUrl/movie/upcoming';
  static const tvPopular = '$tmdbBaseUrl/tv/popular';
  static const tvTopRated = '$tmdbBaseUrl/tv/top_rated';
  static const tvAiringToday = '$tmdbBaseUrl/tv/airing_today';
  static const tvOnTheAir = '$tmdbBaseUrl/tv/on_the_air';
  static const searchMulti = '$tmdbBaseUrl/search/multi';
  static const searchMovie = '$tmdbBaseUrl/search/movie';
  static const genreMovieList = '$tmdbBaseUrl/genre/movie/list';
  static const genreTvList = '$tmdbBaseUrl/genre/tv/list';
  static const discoverMovie = '$tmdbBaseUrl/discover/movie';
  static const discoverTv = '$tmdbBaseUrl/discover/tv';

  static String movieDetail(int id) => '$tmdbBaseUrl/movie/$id';
  static String tvDetail(int id) => '$tmdbBaseUrl/tv/$id';
  static String findByExternalId(String id) => '$tmdbBaseUrl/find/$id';
  static String movieVideos(int id) => '$tmdbBaseUrl/movie/$id/videos';
  static String movieCredits(int id) => '$tmdbBaseUrl/movie/$id/credits';
  static String discoverMovieByGenre(int genreId) => discoverMovie;
  static String discoverTvByGenre(int genreId) => discoverTv;
}

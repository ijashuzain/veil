import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veil/src/core/config/app_environment.dart';

class PlayerSeason {
  const PlayerSeason(this.number, this.episodeCount);
  final int number;
  final int episodeCount;
}

class PlayerEpisode {
  const PlayerEpisode({
    required this.season,
    required this.number,
    this.name = '',
    this.thumbnail,
  });
  final int season;
  final int number;
  final String name;
  final String? thumbnail;
  String get label => name.trim().isEmpty ? 'Episode $number' : name;
  String get code =>
      'S${season.toString().padLeft(2, '0')} - E${number.toString().padLeft(2, '0')}';
}

class EpisodeRepository {
  EpisodeRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final _seasons = <int, List<PlayerSeason>>{};
  final _episodes = <String, List<PlayerEpisode>>{};

  Future<Map<String, dynamic>> _get(String path) async {
    var uri = Uri.parse('${AppEnvironment.tmdbBaseUrl}$path');
    final headers = <String, String>{};
    if (AppEnvironment.usesTmdbProxy) {
      headers['apikey'] = AppEnvironment.supabaseAnonKey;
    } else if (AppEnvironment.tmdbReadAccessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${AppEnvironment.tmdbReadAccessToken}';
    } else {
      uri = uri.replace(
        queryParameters: {'api_key': AppEnvironment.tmdbApiKey},
      );
    }
    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw StateError('Episode catalog unavailable');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<PlayerSeason>> seasons(int id) async {
    if (_seasons.containsKey(id)) return _seasons[id]!;
    final data = await _get('/tv/$id');
    return _seasons[id] = [
      for (final season in data['seasons'] as List? ?? const [])
        if (season is Map &&
            season['season_number'] is int &&
            (season['season_number'] as int) > 0)
          PlayerSeason(
            season['season_number'] as int,
            season['episode_count'] as int? ?? 0,
          ),
    ]..sort((a, b) => a.number.compareTo(b.number));
  }

  Future<List<PlayerEpisode>> episodes(int id, int season) async {
    final key = '$id:$season';
    if (_episodes.containsKey(key)) return _episodes[key]!;
    final data = await _get('/tv/$id/season/$season');
    return _episodes[key] = [
      for (final episode in data['episodes'] as List? ?? const [])
        if (episode is Map && episode['episode_number'] is int)
          PlayerEpisode(
            season: season,
            number: episode['episode_number'] as int,
            name: episode['name'] as String? ?? '',
            thumbnail: AppEnvironment.tmdbImageUrl(
              'w300',
              episode['still_path'] as String?,
            ),
          ),
    ]..sort((a, b) => a.number.compareTo(b.number));
  }

  void dispose() => _client.close();
}

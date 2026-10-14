import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:veil/app/services/supabase_services/supabase_service.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/shared/models/playback_request.dart';

class SharedSubtitleRepository {
  SharedSubtitleRepository({
    required this.client,
    Uri? endpoint,
    String? Function()? accessToken,
  }) : endpoint =
           endpoint ??
           Uri.parse('${AppEnvironment.supabaseUrl}/functions/v1/subtitles'),
       accessToken =
           accessToken ??
           (() => SupabaseService.client?.auth.currentSession?.accessToken);

  final http.Client client;
  final Uri endpoint;
  final String? Function() accessToken;
  final _cache = <String, List<StreamSubtitle>>{};

  Map<String, String> get headers {
    final token = accessToken();
    if (token == null) return {};
    return {
      'Authorization': 'Bearer $token',
      'apikey': AppEnvironment.supabaseAnonKey,
    };
  }

  Future<List<StreamSubtitle>> search(PlaybackRequest request) async {
    final id = request.item.remoteId;
    if (id == null || id <= 0 || accessToken() == null) return [];
    final tv = request.item.mediaType == 'tv' || request.item.type == 'Series';
    final key = '$id:$tv:${request.safeSeason}:${request.safeEpisode}';
    if (_cache.containsKey(key)) return _cache[key]!;
    final uri = endpoint.replace(
      queryParameters: {
        'action': 'search',
        'tmdb_id': '$id',
        'type': tv ? 'episode' : 'movie',
        'title': request.item.title,
        'year': '${request.item.year}',
        if (tv) 'season': '${request.safeSeason}',
        if (tv) 'episode': '${request.safeEpisode}',
      },
    );
    final response = await client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 35));
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tracks = <StreamSubtitle>[];
    for (final raw in (data['tracks'] as List? ?? [])) {
      if (raw is! Map || raw['downloadUrl'] is! String) continue;
      final language = raw['language'] as String? ?? '';
      tracks.add(
        StreamSubtitle(
          url: endpoint.replace(
            queryParameters: {
              'action': 'download',
              'url': raw['downloadUrl'] as String,
            },
          ),
          label: language,
          language: language,
          source: raw['source'] == 'OpenSubtitles fallback'
              ? 'OpenSubtitles fallback'
              : 'Wyzie',
          release: raw['release'] as String? ?? '',
        ),
      );
    }
    // Retry empty searches later; unavailable upstreams should not poison cache.
    if (tracks.isNotEmpty) _cache[key] = tracks;
    return tracks;
  }
}

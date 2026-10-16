import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:veil/app/services/supabase_services/supabase_service.dart';
import '../models/resolved_stream.dart';

class WebStreamResolver implements StreamResolver {
  static Future<void> release(ResolvedStream? stream) async {
    if (stream == null || stream.url.origin != Uri.parse(baseUrl).origin) {
      return;
    }
    final parts = stream.url.pathSegments;
    final session = parts.indexOf('session');
    if (session < 0 || session + 1 >= parts.length) return;
    try {
      await http
          .delete(Uri.parse('$baseUrl/session/${parts[session + 1]}'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      /* Idle expiry also cleans up abandoned sessions. */
    }
  }

  static const baseUrl = String.fromEnvironment(
    'WEB_PLAYER_BASE_URL',
    defaultValue: 'https://api.vexellab.com/veil-player',
  );
  final _client = http.Client();
  bool _disposed = false;

  @override
  Future<ResolvedStream> resolve(Uri entryUrl) async {
    final token = SupabaseService.client?.auth.currentSession?.accessToken;
    if (token == null) {
      throw const StreamResolutionException(
        'Please sign in to play this video.',
      );
    }
    final parts = entryUrl.pathSegments;
    if (parts.length < 3) {
      throw const StreamResolutionException('Missing content identity.');
    }
    final response = await _client
        .post(
          Uri.parse('$baseUrl/resolve'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'provider': 'cinesrc',
            'type': parts[1],
            'id': int.tryParse(parts[2]),
            if (parts[1] == 'tv')
              'season': int.tryParse(entryUrl.queryParameters['s'] ?? '1'),
            if (parts[1] == 'tv')
              'episode': int.tryParse(entryUrl.queryParameters['e'] ?? '1'),
          }),
        )
        .timeout(const Duration(seconds: 170));
    if (_disposed) throw const StreamResolutionException('Playback cancelled.');
    if (response.statusCode != 200) {
      throw StreamResolutionException(switch (response.statusCode) {
        401 => 'Please sign in again to play this video.',
        403 => 'Premium playback is required.',
        429 => 'Player is busy. Please retry shortly.',
        _ => 'Could not prepare this stream. Please retry.',
      });
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = Uri.parse(data['url'] as String);
    if (url.origin != Uri.parse(baseUrl).origin ||
        !url.path.startsWith('${Uri.parse(baseUrl).path}/session/')) {
      throw const StreamResolutionException('Invalid playback session.');
    }
    return ResolvedStream(
      url: url,
      masterUrl: url,
      format: NativeStreamFormat.hls,
      headers: const {},
      resolvedAt: DateTime.now(),
      provider: 'cinesrc',
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _client.close();
  }
}

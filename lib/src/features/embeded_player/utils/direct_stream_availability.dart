import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<bool> isDirectStreamAvailable(
  Uri url, {
  http.Client? client,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final ownsClient = client == null;
  final httpClient = client ?? http.Client();

  try {
    final response = await httpClient
        .get(
          url,
          headers: const {
            'accept':
                'application/vnd.apple.mpegurl, application/x-mpegURL, */*',
          },
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        '[DirectStreamAvailability] unavailable status=${response.statusCode}',
      );
      return false;
    }

    return isPlayableHlsPlaylist(response.body);
  } catch (error) {
    debugPrint('[DirectStreamAvailability] check failed: $error');
    return false;
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }
}

@visibleForTesting
bool isPlayableHlsPlaylist(String body) {
  final trimmed = body.trim();
  if (!trimmed.contains('#EXTM3U')) return false;

  final lower = trimmed.toLowerCase();
  if (lower.contains('not available') ||
      lower.contains('unavailable') ||
      lower.contains('not found')) {
    return false;
  }

  return trimmed.contains('#EXT-X-STREAM-INF') ||
      trimmed.contains('#EXTINF') ||
      trimmed.contains('.m3u8') ||
      trimmed.contains('.ts') ||
      trimmed.contains('.m4s');
}

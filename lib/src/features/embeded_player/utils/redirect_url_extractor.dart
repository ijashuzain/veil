import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

Future<Uri> extractRedirectUrl(
  String url, {
  int maxRedirects = 10,
  http.Client? client,
  bool skipNetwork = kIsWeb,
}) async {
  if (skipNetwork) {
    final uri = _normalizeBrowserNavigatedUrl(Uri.parse(url));
    debugPrint('[RedirectExtractor] browser navigation ${_summarizeUri(uri)}');
    return uri;
  }

  final ownsClient = client == null;
  final httpClient = client ?? http.Client();

  try {
    var currentUrl = Uri.parse(url);
    debugPrint('[RedirectExtractor] start ${_summarizeUri(currentUrl)}');

    for (var i = 0; i < maxRedirects; i++) {
      final request = http.Request('GET', currentUrl)
        ..followRedirects = false
        ..headers.addAll({
          'user-agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
          'accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        });

      final response = await httpClient.send(request);
      await response.stream.drain();

      final location = response.headers['location'];
      debugPrint(
        '[RedirectExtractor] hop=${i + 1} status=${response.statusCode} '
        'url=${_summarizeUri(currentUrl)} '
        'location=${_summarizeLocation(location)}',
      );

      if (location == null || location.isEmpty) {
        debugPrint('[RedirectExtractor] final ${_summarizeUri(currentUrl)}');
        return currentUrl;
      }

      currentUrl = currentUrl.resolve(location);
    }

    debugPrint(
      '[RedirectExtractor] too many redirects max=$maxRedirects '
      'start=${_summarizeUri(Uri.parse(url))}',
    );
    throw StateError('Too many redirects for $url');
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }
}

Uri _normalizeBrowserNavigatedUrl(Uri uri) {
  if (uri.host == 'www.playimdb.com') {
    return uri.replace(host: 'playimdb.com');
  }
  return uri;
}

String _summarizeLocation(String? location) {
  if (location == null || location.isEmpty) return '<none>';

  final uri = Uri.tryParse(location);
  if (uri == null || !uri.hasScheme) {
    return location.length > 120
        ? '${location.substring(0, 120)}...'
        : location;
  }

  return _summarizeUri(uri);
}

String _summarizeUri(Uri uri) {
  final buffer = StringBuffer()
    ..write(uri.scheme)
    ..write('://')
    ..write(uri.host);

  if (uri.hasPort) {
    buffer
      ..write(':')
      ..write(uri.port);
  }

  buffer.write(uri.path.isEmpty ? '/' : uri.path);

  if (uri.hasQuery) {
    buffer.write('?queryLength=${uri.query.length}');
  }

  if (uri.hasFragment) {
    buffer.write('#fragmentLength=${uri.fragment.length}');
  }

  return buffer.toString();
}

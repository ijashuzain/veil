import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:veil/src/features/embeded_player/utils/playback_webview_policy.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/utils/stream_capture_script.dart';

class CineSrcStreamResolver implements StreamResolver {
  static final _recent = <Uri, ResolvedStream>{};
  static void invalidate(Uri url) => _recent.remove(url);
  CineSrcStreamResolver({
    this.timeout = const Duration(seconds: 25),
    this.provider = 'cinesrc',
  });
  final String provider;
  final _client = http.Client();
  final Duration timeout;
  HeadlessInAppWebView? _webView;
  Completer<ResolvedStream>? _result;
  bool _disposed = false;
  bool _accepting = false;
  Future<void>? _runFuture;
  Future<void>? _closing;

  @override
  Future<ResolvedStream> resolve(Uri entryUrl) async {
    if (_disposed || _result != null) {
      throw const StreamResolutionException('Resolver is no longer available.');
    }
    final expectedHost = {
      'cinesrc': 'cinesrc.st',
      'vidsrc': 'vsembed.ru',
      'cinejoy': 'cinejoy.pk',
      'vidlink': 'vidlink.pro',
    }[provider];
    if (entryUrl.scheme != 'https' || entryUrl.host != expectedHost) {
      throw const StreamResolutionException('Unsupported stream provider.');
    }
    final cached = _recent[entryUrl];
    if (cached != null &&
        DateTime.now().difference(cached.resolvedAt) <
            const Duration(seconds: 60)) {
      return cached;
    }
    final result = _result = Completer<ResolvedStream>();
    // Cancellation can occur while the native headless view is being created.
    unawaited(
      result.future.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final policy = PlaybackWebViewPolicy(
      playerUrl: entryUrl.toString(),
      loadAsPage: true,
    );
    _webView = HeadlessInAppWebView(
      initialSize: const Size(874, 402),
      initialUrlRequest: URLRequest(
        url: WebUri.uri(
          entryUrl.replace(
            queryParameters: {
              ...entryUrl.queryParameters,
              'autoplay': 'false',
              'muted': 'true',
            },
          ),
        ),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        javaScriptCanOpenWindowsAutomatically: false,
        supportMultipleWindows: true,
        useShouldOverrideUrlLoading: true,
        useShouldInterceptRequest: isAndroid,
        isInspectable: false,
        regexToCancelSubFramesLoading: playbackBlockedSubframePattern,
        contentBlockers: isAndroid
            ? []
            : [
                for (final domain in playbackBlockedDomains)
                  ContentBlocker(
                    trigger: ContentBlockerTrigger(
                      urlFilter:
                          '^https?://([^/]*\\.)?${RegExp.escape(domain)}'
                          r'[/:]',
                    ),
                    action: ContentBlockerAction(
                      type: ContentBlockerActionType.BLOCK,
                    ),
                  ),
                for (final filter in playbackBlockedScriptUrlFilters)
                  ContentBlocker(
                    trigger: ContentBlockerTrigger(urlFilter: filter),
                    action: ContentBlockerAction(
                      type: ContentBlockerActionType.BLOCK,
                    ),
                  ),
              ],
      ),
      initialUserScripts: UnmodifiableListView([
        UserScript(
          source: nativeStreamCaptureScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          forMainFrameOnly: false,
        ),
      ]),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'veilResolvedStream',
          callback: (args) async {
            if (_disposed ||
                _accepting ||
                result.isCompleted ||
                args.isEmpty ||
                args.first is! Map) {
              return null;
            }
            final data = Map<String, dynamic>.from(args.first as Map);
            final url = Uri.tryParse(data['url'] as String? ?? '');
            if (url != null &&
                data['direct'] == true &&
                isUsableHlsCandidate(url, '#EXTM3U\n#EXTINF:1\nx.ts')) {
              try {
                final response = await _client
                    .get(
                      url,
                      headers: {
                        'Referer':
                            data['referer']?.toString() ?? entryUrl.toString(),
                        'User-Agent': data['userAgent']?.toString() ?? '',
                      },
                    )
                    .timeout(const Duration(seconds: 6));
                if (response.statusCode == 200) {
                  data['playlist'] = response.body;
                }
              } catch (_) {
                return null;
              }
              if (_disposed || _accepting || result.isCompleted) return null;
            }
            if (url == null ||
                !isUsableHlsCandidate(url, data['playlist'] as String? ?? '')) {
              return null;
            }
            _accepting = true;
            try {
              final nativeUrl = preferredNativeHlsUrl(
                url,
                data['playlist'] as String,
              );
              if (!isUsableHlsCandidate(
                nativeUrl,
                data['playlist'] as String,
              )) {
                throw const StreamResolutionException(
                  'Unsupported stream rendition.',
                );
              }
              final headers = <String, String>{};
              if (data['headers'] is Map) {
                for (final item in (data['headers'] as Map).entries) {
                  final name = item.key.toString();
                  if (!{
                    'host',
                    'content-length',
                    'connection',
                    'range',
                  }.contains(name.toLowerCase())) {
                    headers[name] = item.value.toString();
                  }
                }
              }
              headers['Referer'] =
                  data['referer'] as String? ?? entryUrl.toString();
              headers['User-Agent'] = data['userAgent'] as String? ?? '';
              final cookies = await CookieManager.instance().getCookies(
                url: WebUri.uri(nativeUrl),
              );
              if (cookies.isNotEmpty) {
                headers['Cookie'] = cookies
                    .map((cookie) => '${cookie.name}=${cookie.value}')
                    .join('; ');
              }
              if (!_disposed && !result.isCompleted) {
                final subtitles = parseHlsSubtitles(
                  url,
                  data['playlist'] as String,
                );
                if (data['subtitles'] is List) {
                  for (final raw in data['subtitles'] as List) {
                    if (raw is! Map || raw['url'] is! String) continue;
                    final subtitleUrl = Uri.tryParse(raw['url'] as String);
                    if (subtitleUrl?.scheme != 'https') continue;
                    if (!subtitles.any((item) => item.url == subtitleUrl)) {
                      subtitles.add(
                        StreamSubtitle(
                          url: subtitleUrl!,
                          label: raw['label']?.toString() ?? 'Subtitles',
                          language: raw['language']?.toString() ?? '',
                        ),
                      );
                    }
                  }
                }
                result.complete(
                  ResolvedStream(
                    url: nativeUrl,
                    format: NativeStreamFormat.hls,
                    headers: headers,
                    resolvedAt: DateTime.now(),
                    masterUrl: url,
                    qualities: parseHlsQualities(
                      url,
                      data['playlist'] as String,
                    ),
                    subtitles: subtitles,
                    subtitleRequests: [
                      if (data['subtitleRequests'] is List)
                        for (final raw in data['subtitleRequests'] as List)
                          if (raw is Map &&
                              Uri.tryParse(
                                    raw['url']?.toString() ?? '',
                                  )?.scheme ==
                                  'https' &&
                              Uri.tryParse(
                                    raw['url']?.toString() ?? '',
                                  )?.host ==
                                  entryUrl.host)
                            SubtitleRequest(
                              url: Uri.parse(raw['url'].toString()),
                              method: raw['method']?.toString() ?? 'GET',
                              body: raw['body'] as String?,
                            ),
                    ],
                    provider: provider,
                  ),
                );
              }
            } catch (_) {
              if (!result.isCompleted) {
                result.completeError(
                  const StreamResolutionException(
                    'Could not capture the stream session.',
                  ),
                );
              }
            }
            return null;
          },
        );
      },
      shouldOverrideUrlLoading: (_, action) async =>
          policy.allowsNavigation(
            action.request.url?.toString() ?? '',
            isMainFrame: action.isForMainFrame,
          )
          ? NavigationActionPolicy.ALLOW
          : NavigationActionPolicy.CANCEL,
      shouldInterceptRequest: (_, request) async =>
          isBlockedPlaybackResource(request.url.toString())
          ? WebResourceResponse(
              contentType: 'text/plain',
              data: Uint8List(0),
              statusCode: 403,
              reasonPhrase: 'Blocked',
            )
          : null,
      onCreateWindow: (_, _) async => false,
      onReceivedError: (_, request, _) {
        if (request.isForMainFrame == true && !result.isCompleted) {
          result.completeError(
            const StreamResolutionException(
              'The stream provider could not be reached.',
            ),
          );
        }
      },
    );
    try {
      _runFuture = _webView!.run();
      unawaited(
        _runFuture!.then<void>(
          (_) {},
          onError: (Object _, StackTrace _) {
            if (!result.isCompleted) {
              result.completeError(
                const StreamResolutionException(
                  'Could not start the stream resolver.',
                ),
              );
            }
          },
        ),
      );
      final stream = await result.future.timeout(
        timeout,
        onTimeout: () => throw const StreamResolutionException(
          'Stream resolution timed out.',
        ),
      );
      if (!_disposed) {
        if (_recent.length >= 3) _recent.remove(_recent.keys.first);
        _recent[entryUrl] = stream;
      }
      return stream;
    } finally {
      // Native playback never depends on a retained browser or its audio.
      await _closeWebView();
    }
  }

  Future<void> _closeWebView() => _closing ??= _disposeWebView();

  Future<void> _disposeWebView() async {
    final view = _webView;
    _webView = null;
    if (view != null) {
      try {
        await _runFuture;
      } catch (_) {}
      await view.dispose();
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _client.close();
    final result = _result;
    if (result != null && !result.isCompleted) {
      result.completeError(
        const StreamResolutionException('Stream resolution cancelled.'),
      );
    }
    await _closeWebView();
  }
}

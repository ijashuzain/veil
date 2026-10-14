import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:veil/src/features/embeded_player/utils/playback_webview_policy.dart';

/// Request protection is installed before the first page load. Keep stream
/// requests untouched: no preflights, proxying, or generic EasyList URL matches.
class MobilePlaybackWebView extends StatefulWidget {
  /// Live device probes can observe the real player without a separate WebView.
  /// These hooks are inert in release builds and contain no account data.
  @visibleForTesting
  static List<UserScript> debugUserScripts = const [];

  @visibleForTesting
  static void Function(InAppWebViewController)? debugOnWebViewCreated;

  @visibleForTesting
  static void Function(Map<String, Object?>)? debugOnDiagnostic;

  @visibleForTesting
  static void Function(InAppWebViewSettings)? debugConfigureSettings;

  const MobilePlaybackWebView({
    super.key,
    required this.policy,
    this.html,
    this.onPageReady,
    this.onMediaReady,
    this.onFailure,
    this.onRendererFailure,
    this.onAwaitingPlay,
    this.onPlayRequested,
    this.onMediaError,
  });

  final PlaybackWebViewPolicy policy;
  final String? html;
  final VoidCallback? onPageReady;
  final VoidCallback? onMediaReady;
  final VoidCallback? onFailure;
  final VoidCallback? onRendererFailure;
  final VoidCallback? onAwaitingPlay;
  final VoidCallback? onPlayRequested;
  final ValueChanged<int>? onMediaError;

  @override
  State<MobilePlaybackWebView> createState() => _MobilePlaybackWebViewState();
}

class _MobilePlaybackWebViewState extends State<MobilePlaybackWebView> {
  // Retain the platform widget/controller across loading-indicator rebuilds.
  late final _webView = _createWebView();

  @override
  Widget build(BuildContext context) => _webView;

  InAppWebView _createWebView() {
    final policy = widget.policy;
    final html = widget.html;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return InAppWebView(
      initialUrlRequest: html == null
          ? URLRequest(url: WebUri(policy.playerUrl))
          : null,
      initialData: html == null
          ? null
          : InAppWebViewInitialData(
              data: html,
              baseUrl: WebUri(policy.wrapperBaseUrl),
            ),
      initialSettings: _configureSettings(
        InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          allowBackgroundAudioPlaying: false,
          useHybridComposition: true,
          hardwareAcceleration: true,
          transparentBackground: true,
          supportZoom: false,
          javaScriptCanOpenWindowsAutomatically: false,
          // Required so target=_blank is sent to onCreateWindow, not silently
          // loaded in the existing player window on Android.
          supportMultipleWindows: true,
          useShouldOverrideUrlLoading: true,
          useShouldInterceptRequest: isAndroid,
          regexToCancelSubFramesLoading: playbackBlockedSubframePattern,
          // Android's plugin content blockers issue a MIME-probing HEAD for every
          // resource. Use interception there to avoid doubling stream requests.
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
                      trigger: ContentBlockerTrigger(
                        urlFilter: filter,
                        resourceType: [
                          ContentBlockerTriggerResourceType.SCRIPT,
                        ],
                      ),
                      action: ContentBlockerAction(
                        type: ContentBlockerActionType.BLOCK,
                      ),
                    ),
                ],
          disableDefaultErrorPage: true,
          allowsLinkPreview: false,
          isInspectable: false,
        ),
      ),
      initialUserScripts: UnmodifiableListView([
        if (kDebugMode) ...MobilePlaybackWebView.debugUserScripts,
        UserScript(
          source: _playbackGuardScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          forMainFrameOnly: false,
        ),
      ]),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'veilMediaReady',
          callback: (_) {
            if (mounted) widget.onMediaReady?.call();
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'veilAwaitingPlay',
          callback: (_) {
            _diagnostic({'kind': 'awaitingPlay'});
            if (mounted) widget.onAwaitingPlay?.call();
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'veilPlayRequested',
          callback: (_) {
            _diagnostic({'kind': 'playRequested'});
            if (mounted) widget.onPlayRequested?.call();
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'veilMediaError',
          callback: (args) {
            final code = args.isNotEmpty && args.first is num
                ? (args.first as num).toInt()
                : 0;
            _diagnostic({'kind': 'mediaError', 'code': code});
            if (mounted && code >= 2 && code <= 4) {
              widget.onMediaError?.call(code);
            }
            return null;
          },
        );
        if (kDebugMode) {
          MobilePlaybackWebView.debugOnWebViewCreated?.call(controller);
        }
      },
      shouldOverrideUrlLoading: (_, action) async {
        final url = action.request.url?.toString() ?? '';
        final allowed = policy.allowsNavigation(
          url,
          isMainFrame: action.isForMainFrame,
        );
        if (action.isForMainFrame &&
            policy.loadAsPage &&
            url == 'about:blank' &&
            mounted) {
          (widget.onRendererFailure ?? widget.onFailure)?.call();
        }
        _diagnostic({
          'kind': 'navigation',
          'url': url,
          'main': action.isForMainFrame,
          'allowed': allowed,
        });
        return allowed
            ? NavigationActionPolicy.ALLOW
            : NavigationActionPolicy.CANCEL;
      },
      shouldInterceptRequest: (_, request) async {
        if (!isBlockedPlaybackResource(request.url.toString())) return null;
        return WebResourceResponse(
          contentType: 'text/plain',
          contentEncoding: 'utf-8',
          data: Uint8List(0),
          statusCode: 403,
          reasonPhrase: 'Blocked',
        );
      },
      onCreateWindow: (_, action) async {
        _diagnostic({'kind': 'popup', 'url': action.request.url?.toString()});
        return false;
      },
      // Never dispatch provider downloads or app links to another app.
      onDownloadStartRequest: (_, _) {},
      onPermissionRequest: (_, request) async => PermissionResponse(
        resources: request.resources,
        action: PermissionResponseAction.DENY,
      ),
      onLoadStop: (_, _) {
        if (mounted) widget.onPageReady?.call();
      },
      onReceivedHttpError: (_, request, response) {
        _diagnostic({
          'kind': 'httpError',
          'url': request.url.toString(),
          'status': response.statusCode,
          'main': request.isForMainFrame,
        });
        if (request.url.toString() == policy.playerUrl &&
            (response.statusCode ?? 0) >= 400) {
          if (mounted) widget.onFailure?.call();
        }
      },
      onReceivedError: (_, request, error) {
        _diagnostic({
          'kind': 'resourceError',
          'url': request.url.toString(),
          'message': error.description,
          'main': request.isForMainFrame,
        });
        if (request.url.toString() == policy.playerUrl ||
            (request.isForMainFrame == true &&
                policy.allowsNavigation(
                  request.url.toString(),
                  isMainFrame: true,
                ))) {
          if (mounted) widget.onFailure?.call();
        }
      },
      onRenderProcessGone: (_, _) {
        if (mounted) (widget.onRendererFailure ?? widget.onFailure)?.call();
      },
      onWebContentProcessDidTerminate: (_) {
        if (mounted) (widget.onRendererFailure ?? widget.onFailure)?.call();
      },
    );
  }

  InAppWebViewSettings _configureSettings(InAppWebViewSettings settings) {
    if (kDebugMode) {
      MobilePlaybackWebView.debugConfigureSettings?.call(settings);
    }
    return settings;
  }

  void _diagnostic(Map<String, Object?> event) {
    if (kDebugMode && mounted) {
      MobilePlaybackWebView.debugOnDiagnostic?.call(event);
    }
  }
}

const _playbackGuardScript = r'''
(function () {
  if (window.__veilPlaybackGuard) return;
  window.__veilPlaybackGuard = true;
  try {
    Object.defineProperty(window, 'open', {
      value: function () { return null; }, writable: false, configurable: false
    });
  } catch (_) { window.open = function () { return null; }; }
  document.addEventListener('click', function (event) {
    const link = event.target && event.target.closest &&
      event.target.closest('a[href]');
    if (!link) return;
    let url;
    try { url = new URL(link.href, location.href); } catch (_) { return; }
    if (!/^https?:$/.test(url.protocol) || link.target === '_blank' ||
        link.hasAttribute('download')) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }, true);

  let reported = false;
  let mediaErrorTimer = null;
  function notify(name, value) {
    if (!window.flutter_inappwebview || !window.flutter_inappwebview.callHandler) return false;
    window.flutter_inappwebview.callHandler(name, value);
    return true;
  }
  function isPlayerVideo(video) {
    if (!video || video.tagName !== 'VIDEO') return false;
    const rect = video.getBoundingClientRect();
    return rect.width >= 160 && rect.height >= 90;
  }
  function report(video) {
    if (!isPlayerVideo(video) ||
        video.readyState < 2 || video.videoWidth <= 0) return;
    clearTimeout(mediaErrorTimer);
    if (!reported) reported = notify('veilMediaReady');
  }
  ['loadeddata', 'canplay', 'playing'].forEach(function (event) {
    document.addEventListener(event, function (e) { report(e.target); }, true);
  });
  window.addEventListener('flutterInAppWebViewPlatformReady', function () {
    document.querySelectorAll('video').forEach(report);
    checkPlayControl();
  });
  document.addEventListener('play', function (event) {
    if (isPlayerVideo(event.target)) notify('veilPlayRequested');
  }, true);
  document.addEventListener('error', function (event) {
    const video = event.target;
    if (!isPlayerVideo(video) || !video.error || video.error.code < 2) return;
    const code = video.error.code;
    reported = false;
    clearTimeout(mediaErrorTimer);
    // JWPlayer may try another source. Let that recovery complete before
    // surfacing an error, while retaining the code before JW clears it.
    mediaErrorTimer = setTimeout(function () { notify('veilMediaError', code); }, 1200);
  }, true);

  // Vidsrc first shows a poster/Play gate and only creates video after a click.
  // Waiting at that gate is not a stalled video download.
  let awaitingPlayReported = false;
  let unavailableReported = false;
  function checkPlayControl() {
    if (!unavailableReported) {
      const unavailable = Array.from(document.querySelectorAll('h1, h2, p')).some(function (el) {
        return el.getBoundingClientRect().width > 0 &&
          /^We Couldn't Find This Content/i.test(el.textContent.trim());
      });
      if (unavailable) unavailableReported = notify('veilMediaError', 4);
    }
    if (awaitingPlayReported) return;
    const button = document.getElementById('bigPlay');
    if (!button || button.disabled || button.getBoundingClientRect().width <= 0) return;
    awaitingPlayReported = notify('veilAwaitingPlay');
    if (awaitingPlayReported) playControlObserver.disconnect();
  }
  const playControlObserver = new MutationObserver(checkPlayControl);
  playControlObserver.observe(document, {
    childList: true, subtree: true, attributes: true,
    attributeFilter: ['class', 'style', 'disabled']
  });
  document.addEventListener('DOMContentLoaded', checkPlayControl);
  document.addEventListener('click', function (event) {
    const button = event.target && event.target.closest && event.target.closest('#bigPlay');
    if (button) notify('veilPlayRequested');
  }, true);
})();
''';

/// Intentionally excludes popup and top-navigation permissions.
const playbackIframeSandbox =
    'allow-scripts allow-same-origin allow-forms allow-presentation';

const playbackWrapperBaseUrl = 'https://flutter-player.local/';

/// Targeted ad networks, not generic URL fragments that also match players.
/// Bundled so protection does not depend on a filter download at startup.
const playbackBlockedDomains = {
  'doubleclick.net',
  'googlesyndication.com',
  'googleadservices.com',
  'adservice.google.com',
  'ads.pubmatic.com',
  'adnxs.com',
  'adsrvr.org',
  'adsafeprotected.com',
  'adsterra.com',
  'adsterratools.com',
  'propellerads.com',
  'popads.net',
  'popcash.net',
  'trafficjunky.net',
  'exoclick.com',
  'exosrv.com',
  'juicyads.com',
  'hilltopads.net',
  'clickadu.com',
  'onclicka.com',
  'onclck.com',
  'onclkds.com',
  'syndication.realsrv.com',
  'outbrain.com',
  'taboola.com',
  'zedo.com',
  'theajack.github.io',
  // Observed ad/identity SDKs in live provider playback, not stream CDNs.
  'adexchangerapid.com',
  'connatix.com',
  'id5-sync.com',
  'crwdcntrl.net',
  'dtscout.com',
  'onaudience.com',
};

/// The provider vendors this detector on its own domain. It falsely aborts
/// embedded WebViews to about:blank, so a domain-only filter cannot protect them.
const playbackBlockedScriptUrlFilters = [
  r'^https?://[^/]+/(.*/)?disable-devtool(\.min)?\.js',
];
final _blockedScriptPath = RegExp(r'(^|/)disable-devtool(\.min)?\.js$');

bool _matchesHost(String host, String allowedHost) =>
    host == allowedHost || host.endsWith('.$allowedHost');

String _normalizeHost(String host) =>
    host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');

bool isBlockedPlaybackResource(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final host = _normalizeHost(uri.host);
  return playbackBlockedDomains.any((domain) => _matchesHost(host, domain)) ||
      _blockedScriptPath.hasMatch(uri.path.toLowerCase());
}

/// Also applied natively to Android subframes, whose navigation callbacks are
/// not reliably delivered to Dart. Media blob URLs are not frame navigations.
final playbackBlockedSubframePattern =
    r'(?i)^(?!(https?://|about:blank$|about:srcdoc$)).*|^https?://([^/]*\.)?('
    '${playbackBlockedDomains.map(RegExp.escape).join('|')}'
    r')([/:]|$).*';

class PlaybackWebViewPolicy {
  PlaybackWebViewPolicy({
    required this.playerUrl,
    this.loadAsPage = false,
    this.wrapperBaseUrl = playbackWrapperBaseUrl,
  });

  final String playerUrl;
  final bool loadAsPage;
  final String wrapperBaseUrl;

  bool allowsNavigation(String url, {required bool isMainFrame}) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.userInfo.isNotEmpty) return false;
    if (url == 'about:blank' || url == 'about:srcdoc') {
      return !isMainFrame || !loadAsPage;
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') return false;
    if (uri.host.isEmpty || isBlockedPlaybackResource(url)) return false;
    if (!isMainFrame) return true;

    if (!loadAsPage) {
      final wrapper = Uri.parse(wrapperBaseUrl);
      return uri.origin == wrapper.origin && uri.path == wrapper.path;
    }

    final playerHost = _normalizeHost(Uri.parse(playerUrl).host);
    final host = _normalizeHost(uri.host);
    if (_matchesHost(host, playerHost)) return true;
    // Legacy Vidsrc entry URLs redirect to this provider's replacement host.
    return playerHost == 'streamimdb.ru' && _matchesHost(host, 'vsembed.ru');
  }
}

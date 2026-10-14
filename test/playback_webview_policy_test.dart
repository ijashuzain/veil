import 'package:flutter_test/flutter_test.dart';
import 'package:veil/src/features/embeded_player/utils/playback_webview_policy.dart';

void main() {
  final policy = PlaybackWebViewPolicy(
    playerUrl: 'https://vidlink.pro/movie/123',
    loadAsPage: true,
  );

  test('provider redirects work without widening to unrelated domains', () {
    for (final url in [
      'https://vidlink.pro/tv/123/2/3',
      'https://cdn.vidlink.pro/player',
    ]) {
      expect(policy.allowsNavigation(url, isMainFrame: true), isTrue);
    }
    for (final url in [
      'https://vidlink.pro.evil.test/',
      'https://evilvidlink.pro/',
      'https://vsembed.ru/',
      'https://vidlink.pro@evil.test/',
    ]) {
      expect(policy.allowsNavigation(url, isMainFrame: true), isFalse);
    }
    final multiLabel = PlaybackWebViewPolicy(
      playerUrl: 'https://player.example.co.uk/watch',
      loadAsPage: true,
    );
    expect(
      multiLabel.allowsNavigation('https://other.co.uk/', isMainFrame: true),
      isFalse,
    );
  });

  test('blocks app links in every frame before any filter initialization', () {
    for (final url in [
      'intent://ads/#Intent;scheme=market;end',
      'market://details?id=test',
      'tel:123',
      'javascript:window.open("https://ad.test")',
      'data:text/html,ad',
      'file:///tmp/ad.html',
    ]) {
      for (final mainFrame in [true, false]) {
        expect(policy.allowsNavigation(url, isMainFrame: mainFrame), isFalse);
      }
    }
  });

  test('blocks ad domains without matching stream URL keywords', () {
    for (final url in [
      'https://doubleclick.net/ad',
      'https://ads.doubleclick.net/ad',
      'https://ADS.DOUBLECLICK.NET./ad',
    ]) {
      expect(isBlockedPlaybackResource(url), isTrue);
      expect(policy.allowsNavigation(url, isMainFrame: false), isFalse);
    }
    for (final url in [
      'https://cloudorchestranova.com/rcp/player',
      'https://cdn.test/video-ads/player/embed/stream.m3u8',
      'https://notdoubleclick.net/stream.ts',
      'https://doubleclick.net.cdn.test/stream.m3u8',
      'https://cdn.test/stream.m3u8?referer=doubleclick.net',
    ]) {
      expect(isBlockedPlaybackResource(url), isFalse);
      expect(policy.allowsNavigation(url, isMainFrame: false), isTrue);
    }
  });

  test(
    'blocks vendored anti-debug scripts without blocking player bootstrap',
    () {
      for (final url in [
        'https://vsembed.ru/assets/disable-devtool.js?v=123',
        'https://stellarconductornexus.com/embed/iframe_player/assets/disable-devtool.js',
        'https://cdn.test/disable-devtool.min.js',
      ]) {
        expect(isBlockedPlaybackResource(url), isTrue);
      }
      for (final url in [
        'https://vsembed.ru/assets/sbx.js',
        'https://stellarconductornexus.com/embed/iframe_player/assets/vsdec.js',
        'https://cdn.test/player.js',
      ]) {
        expect(isBlockedPlaybackResource(url), isFalse);
      }
    },
  );

  test('provider cannot wipe top-level player with about:blank', () {
    expect(policy.allowsNavigation('about:blank', isMainFrame: true), isFalse);
    expect(policy.allowsNavigation('about:blank', isMainFrame: false), isTrue);
  });

  test('wrapper origin cannot be replaced by provider or arbitrary data', () {
    final wrapper = PlaybackWebViewPolicy(
      playerUrl: 'https://cinesrc.st/embed',
    );
    expect(
      wrapper.allowsNavigation(playbackWrapperBaseUrl, isMainFrame: true),
      isTrue,
    );
    expect(wrapper.allowsNavigation('about:blank', isMainFrame: true), isTrue);
    for (final url in [
      'https://flutter-player.local.evil.test/',
      'https://flutter-player.local/ads',
      'https://cinesrc.st/embed',
    ]) {
      expect(wrapper.allowsNavigation(url, isMainFrame: true), isFalse);
    }
    expect(playbackIframeSandbox, isNot(contains('allow-popups')));
    expect(playbackIframeSandbox, isNot(contains('allow-top-navigation')));
  });
}

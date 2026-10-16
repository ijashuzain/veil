bool get browserIsFullscreen => false;
Stream<bool> browserFullscreenChanges() => const Stream.empty();
Future<void> toggleBrowserFullscreen() async {}
Future<void> exitBrowserFullscreen() async {}

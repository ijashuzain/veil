import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

bool get browserIsFullscreen => web.document.fullscreenElement != null;

Stream<bool> browserFullscreenChanges() {
  late final StreamController<bool> controller;
  final listener = ((web.Event event) => controller.add(
    browserIsFullscreen,
  )).toJS;
  controller = StreamController<bool>(
    onListen: () => web.document.addEventListener('fullscreenchange', listener),
    onCancel: () =>
        web.document.removeEventListener('fullscreenchange', listener),
  );
  return controller.stream;
}

Future<void> toggleBrowserFullscreen() async {
  if (browserIsFullscreen) {
    await exitBrowserFullscreen();
  } else {
    if (!web.document.fullscreenEnabled) {
      throw UnsupportedError('Fullscreen is unavailable in this browser.');
    }
    // Fullscreen the Flutter surface, retaining custom controls and captions.
    await web.document.documentElement!.requestFullscreen().toDart;
  }
}

Future<void> exitBrowserFullscreen() async {
  if (browserIsFullscreen) await web.document.exitFullscreen().toDart;
}

import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:web/web.dart' as web;

@JS('Hls')
external JSFunction? get _hlsConstructor;
@JS('Hls')
extension type _Hls._(JSObject _) implements JSObject {
  external factory _Hls(JSObject config);
  external static bool isSupported();
  external void attachMedia(web.HTMLVideoElement video);
  external void loadSource(String source);
  external void on(String event, JSFunction callback);
  external void destroy();
}
extension type _HlsError._(JSObject _) implements JSObject {
  external bool get fatal;
}

void configureWebVideo() {
  VideoPlayerPlatform.instance = _WebVideoPlatform();
}

class _Player {
  _Player(this.video);
  final web.HTMLVideoElement video;
  final events = StreamController<VideoEvent>();
  final listeners = <VoidCallback>[];
  _Hls? hls;
  bool initialized = false;
  bool disposed = false;
  void emit(VideoEvent event) {
    if (!disposed) events.add(event);
  }

  void listen(String name, VoidCallback callback) {
    final listener = ((web.Event event) => callback()).toJS;
    video.addEventListener(name, listener);
    listeners.add(() => video.removeEventListener(name, listener));
  }

  void ready() {
    if (initialized || !video.duration.isFinite || video.videoWidth == 0) {
      return;
    }
    initialized = true;
    emit(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: Duration(milliseconds: (video.duration * 1000).round()),
        size: Size(video.videoWidth.toDouble(), video.videoHeight.toDouble()),
      ),
    );
  }

  Future<void> dispose() async {
    disposed = true;
    for (final remove in listeners) {
      remove();
    }
    hls?.destroy();
    video.pause();
    video.removeAttribute('src');
    video.load();
    unawaited(events.close());
  }
}

class _WebVideoPlatform extends VideoPlayerPlatform {
  final _players = <int, _Player>{};
  int _next = 0;
  @override
  Future<void> init() async {}
  @override
  Future<int> create(DataSource source) => createWithOptions(
    VideoCreationOptions(
      dataSource: source,
      viewType: VideoViewType.platformView,
    ),
  );
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    final id = ++_next;
    final source = options.dataSource.uri;
    if (source == null) throw UnsupportedError('Network video required');
    final video = web.HTMLVideoElement()
      ..controls = false
      ..autoplay = false
      ..preload = 'auto'
      ..playsInline = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.pointerEvents = 'none';
    final player = _Player(video);
    _players[id] = player;
    ui.platformViewRegistry.registerViewFactory(
      'veil-web-video-$id',
      (_) => video,
    );
    player.listen('canplay', () {
      player.ready();
      player.emit(VideoEvent(eventType: VideoEventType.bufferingEnd));
    });
    player.listen('loadedmetadata', player.ready);
    player.listen(
      'waiting',
      () => player.emit(VideoEvent(eventType: VideoEventType.bufferingStart)),
    );
    player.listen(
      'playing',
      () => player.emit(VideoEvent(eventType: VideoEventType.bufferingEnd)),
    );
    player.listen(
      'play',
      () => player.emit(
        VideoEvent(
          eventType: VideoEventType.isPlayingStateUpdate,
          isPlaying: true,
        ),
      ),
    );
    player.listen(
      'pause',
      () => player.emit(
        VideoEvent(
          eventType: VideoEventType.isPlayingStateUpdate,
          isPlaying: false,
        ),
      ),
    );
    player.listen(
      'ended',
      () => player.emit(VideoEvent(eventType: VideoEventType.completed)),
    );
    player.listen('progress', () {
      final ranges = video.buffered;
      player.emit(
        VideoEvent(
          eventType: VideoEventType.bufferingUpdate,
          buffered: [
            for (var i = 0; i < ranges.length; i++)
              DurationRange(
                Duration(milliseconds: (ranges.start(i) * 1000).round()),
                Duration(milliseconds: (ranges.end(i) * 1000).round()),
              ),
          ],
        ),
      );
    });
    player.listen('error', () {
      if (!player.disposed) {
        player.events.addError(
          PlatformException(
            code: 'web-video',
            message: 'Video source failed. Please retry playback.',
          ),
        );
      }
    });
    try {
      if (options.dataSource.formatHint == VideoFormat.hls) {
        if (video.canPlayType('application/vnd.apple.mpegurl').isNotEmpty) {
          video.src = source;
        } else if (_hlsConstructor != null && _Hls.isSupported()) {
          final hls = _Hls(
            {'startLevel': 0, 'maxBufferLength': 30}.jsify() as JSObject,
          );
          player.hls = hls;
          hls.on(
            'hlsError',
            ((JSString event, _HlsError data) {
              if (!player.disposed && data.fatal) {
                player.events.addError(
                  PlatformException(
                    code: 'web-hls',
                    message: 'Stream interrupted. Please retry playback.',
                  ),
                );
              }
            }).toJS,
          );
          hls.attachMedia(video);
          hls.loadSource(source);
        } else {
          throw StateError(
            'Web video library unavailable. Please reload or try another browser.',
          );
        }
      } else {
        video.src = source;
      }
    } catch (_) {
      _players.remove(id);
      await player.dispose();
      rethrow;
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) =>
      _players[playerId]!.events.stream;
  @override
  Widget buildView(int playerId) =>
      HtmlElementView(viewType: 'veil-web-video-$playerId');
  @override
  Future<void> dispose(int playerId) async {
    await _players.remove(playerId)?.dispose();
  }

  @override
  Future<void> play(int playerId) async {
    await _players[playerId]!.video.play().toDart;
  }

  @override
  Future<void> pause(int playerId) async {
    _players[playerId]!.video.pause();
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _players[playerId]!.video.currentTime = position.inMilliseconds / 1000;
  }

  @override
  Future<Duration> getPosition(int playerId) async => Duration(
    milliseconds: (_players[playerId]!.video.currentTime * 1000).round(),
  );
  @override
  Future<void> setLooping(int playerId, bool looping) async {
    _players[playerId]!.video.loop = looping;
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    _players[playerId]!.video
      ..muted = volume == 0
      ..volume = volume;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    _players[playerId]!.video.playbackRate = speed;
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> setWebOptions(
    int playerId,
    VideoPlayerWebOptions options,
  ) async {}
}

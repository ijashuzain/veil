import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veil/src/features/embeded_player/view/player.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/repository/cinesrc_stream_resolver.dart';
import 'package:veil/src/features/native_player/repository/provider_stream_resolver.dart';
import 'package:veil/src/features/native_player/repository/web_stream_resolver.dart';
import 'package:video_player/video_player.dart';
import 'package:veil/src/features/native_player/utils/playback_intent.dart';
import 'package:veil/src/features/native_player/repository/subtitle_repository.dart';
import 'package:veil/src/features/native_player/view/episode_panel.dart';
import 'package:veil/src/features/native_player/view/player_controls.dart';
import 'package:veil/src/features/native_player/view/player_control_glyph.dart';
import 'package:veil/src/features/native_player/repository/episode_repository.dart';
import 'package:veil/src/features/native_player/utils/language_labels.dart';
import 'package:veil/src/features/native_player/utils/caption_text.dart';
import 'package:veil/src/features/native_player/utils/player_platform.dart';
import 'package:veil/src/features/native_player/utils/browser_fullscreen.dart';
import 'package:veil/src/shared/models/playback_request.dart';
import 'package:veil/src/features/detail/utils/playback_entry_url.dart';

typedef StreamResolverFactory = StreamResolver Function();

class NativePlayerView extends StatefulWidget {
  const NativePlayerView({
    super.key,
    required this.entryUrl,
    required this.title,
    this.resolverFactory,
    this.request,
    this.onEpisodeChanged,
    this.onProgress,
    this.onCompleted,
    this.episodeRepository,
  });
  final Uri entryUrl;
  final String title;
  final StreamResolverFactory? resolverFactory;
  final PlaybackRequest? request;
  final ValueChanged<PlaybackRequest>? onEpisodeChanged;
  final ValueChanged<PlaybackRequest>? onProgress;
  final ValueChanged<PlaybackRequest>? onCompleted;
  final EpisodeRepository? episodeRepository;

  /// Audit telemetry excludes signed URLs, cookies, and provider credentials.
  @visibleForTesting
  static void Function(Map<String, Object?>)? debugOnDiagnostic;
  @visibleForTesting
  static bool debugProbeSource = false;

  @override
  State<NativePlayerView> createState() => _NativePlayerViewState();
}

class _NativePlayerViewState extends State<NativePlayerView>
    with WidgetsBindingObserver {
  StreamResolver? _resolver;
  VideoPlayerController? _controller;
  int _generation = 0;
  String _stage = 'Resolving stream…';
  String? _error;
  bool _loading = true;
  bool _readyReported = false;
  bool _playReported = false;
  int _lastProgressSecond = -1;
  int _lastCheckpointSecond = -15;
  bool _completedRecorded = false;
  double? _seekPreview;
  final _clock = Stopwatch();
  late final _diagnosticCallback = NativePlayerView.debugOnDiagnostic;
  Future<void>? _releaseFuture;
  PlaybackIntent? _intent;
  Timer? _hideTimer;
  bool _controlsVisible = true;
  bool _menuOpen = false;
  String? _panel;
  int _trackTab = 0;
  BoxFit _videoFit = BoxFit.contain;
  String? _subtitleLanguage;
  final _subtitleScrollController = ScrollController();
  final _qualityScrollController = ScrollController();
  bool _tracksLoading = false;
  List<StreamSubtitle> _subtitleTracks = [];
  late final EpisodeRepository _episodeRepository =
      widget.episodeRepository ?? EpisodeRepository();
  String _episodeName = '';
  int _episodeLoad = 0;
  double _brightness = .5;
  bool _brightnessChanged = false;
  bool _gestureLeft = false;
  double _gestureValue = .5;
  double _gestureStartY = 0;
  String? _feedback;
  Timer? _feedbackTimer;
  Offset? _doubleTapPosition;
  Size _playerSize = Size.zero;
  late Uri _entryUrl = widget.entryUrl;
  late PlaybackRequest? _request = widget.request;
  ResolvedStream? _stream;
  final _subtitleRepository = SubtitleRepository();
  StreamSubtitle? _subtitle;
  int _subtitleGeneration = 0;
  String _qualityLabel = 'Auto';
  bool _switchingQuality = false;
  double _volume = 1;
  double _volumeBeforeMute = 1;
  bool _browserFullscreen = false;
  bool _ownsBrowserFullscreen = false;
  StreamSubscription<bool>? _fullscreenSubscription;
  // Keep mobile video in Flutter's compositor: Android platform views can
  // misapply FittedBox transforms/clipping during the first fullscreen rotation.
  VideoViewType get _videoViewType =>
      kIsWeb ? VideoViewType.platformView : VideoViewType.textureView;
  NativeProvider get _provider => _request?.server == PlaybackServer.six
      ? NativeProvider.vidsrc
      : NativeProvider.cinesrc;
  int get _serverNumber => _request?.server == PlaybackServer.six ? 6 : 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      _browserFullscreen = browserIsFullscreen;
      _fullscreenSubscription = browserFullscreenChanges().listen((active) {
        if (!mounted) return;
        setState(() => _browserFullscreen = active);
        if (!active) _ownsBrowserFullscreen = false;
      });
    }
    unawaited(_fullscreen(true));
    unawaited(_start(position: widget.request?.startPosition ?? Duration.zero));
    unawaited(_loadEpisodeName());
    unawaited(_readBrightness());
  }

  Future<void> _start({Duration position = Duration.zero}) async {
    final generation = ++_generation;
    _intent?.dispose();
    _intent = null;
    _hideTimer?.cancel();
    _controlsVisible = true;
    _seekPreview = null;
    _panel = null;
    _menuOpen = false;
    _subtitleTracks = [];
    _clock
      ..reset()
      ..start();
    _readyReported = false;
    _playReported = false;
    _lastProgressSecond = -1;
    _lastCheckpointSecond = -15;
    _completedRecorded = false;
    final previousResolver = _resolver;
    final previousController = _controller;
    _resolver = null;
    _controller = null;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _stage = 'Resolving stream…';
      });
    }
    await previousResolver?.dispose();
    previousController?.removeListener(_onVideoChanged);
    await previousController?.dispose();
    if (!mounted || generation != _generation) return;
    if ((kIsWeb && _provider != NativeProvider.cinesrc) ||
        (!kIsWeb &&
            defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      setState(() {
        _loading = false;
        _error = kIsWeb
            ? 'Player 2 is currently unavailable on web. Please select Player 1.'
            : 'Native playback is available on Android and iOS. Use the embedded player on this platform.';
      });
      return;
    }
    final resolver = _resolver =
        widget.resolverFactory?.call() ??
        (kIsWeb
            ? WebStreamResolver()
            : ProviderStreamResolver(
                providers: [_provider],
                onAttempt: (provider) {
                  if (mounted) setState(() => _stage = 'Resolving stream…');
                },
              ));
    VideoPlayerController? controller;
    try {
      final stream = await resolver.resolve(_entryUrl);
      // Even injected resolvers must obey the browser-free handoff contract.
      await resolver.dispose();
      if (!mounted || generation != _generation) return;
      if (kIsWeb && _stream?.url != stream.url) {
        unawaited(WebStreamResolver.release(_stream));
      }
      _stream = stream;
      _subtitleTracks = stream.subtitles;
      _qualityLabel = stream.url == stream.masterUrl
          ? 'Auto'
          : stream.qualities
                    .where((q) => q.url == stream.url)
                    .firstOrNull
                    ?.label ??
                'Default';
      _emit({
        'kind': 'resolved',
        'format': stream.format.name,
        'host': stream.url.host,
        'resolverDisposed': true,
        'provider': stream.provider,
        'qualities': stream.qualities.length,
        'subtitles': stream.subtitles.length,
      });
      if (!mounted || generation != _generation) return;
      setState(() => _stage = 'Starting player…');
      controller = VideoPlayerController.networkUrl(
        stream.url,
        httpHeaders: stream.headers,
        formatHint: stream.format == NativeStreamFormat.hls
            ? VideoFormat.hls
            : VideoFormat.other,
        viewType: _videoViewType,
      );
      _controller = controller;
      _intent = _createIntent(controller);
      controller.addListener(_onVideoChanged);
      setState(() {});
      await controller.initialize().timeout(const Duration(seconds: 25));
      if (!mounted || generation != _generation) return;
      await controller.setVolume(_volume);
      if (position > Duration.zero) {
        await controller.seekTo(position).timeout(const Duration(seconds: 15));
      }
      try {
        await controller.play();
      } catch (_) {
        if (!kIsWeb) rethrow;
        _intent?.setPlaying(false);
        _notice('Tap Play to start playback.');
      }
      if (!mounted || generation != _generation) return;
      setState(() => _loading = false);
      _scheduleHide();
    } catch (error) {
      if (!mounted || generation != _generation) return;
      CineSrcStreamResolver.invalidate(
        nativeProviderEntry(_entryUrl, _provider),
      );
      _emit({'kind': 'failure', 'type': error.runtimeType.toString()});
      controller?.removeListener(_onVideoChanged);
      if (_controller == controller) _controller = null;
      await controller?.dispose();
      if (!mounted || generation != _generation) return;
      await resolver.dispose();
      setState(() {
        _loading = false;
        _error = error is StreamResolutionException
            ? error.message
            : 'This stream could not be played natively. Retry or use the embedded player.';
      });
    } finally {
      await resolver.dispose();
      if (_resolver == resolver) _resolver = null;
    }
  }

  void _onVideoChanged() {
    if (!mounted) return;
    final value = _controller?.value;
    if (value == null) return;
    if (value.isInitialized && !_readyReported) {
      _readyReported = true;
      _emit({
        'kind': 'nativeReady',
        'width': value.size.width,
        'height': value.size.height,
        'duration': value.duration.inMilliseconds / 1000,
      });
    }
    if (value.isPlaying &&
        value.position >= const Duration(seconds: 3) &&
        !_playReported) {
      _playReported = true;
      _emit({
        'kind': 'nativePlaying',
        'time': value.position.inMilliseconds / 1000,
      });
    }
    final second = value.position.inSeconds;
    if (second != _lastProgressSecond) {
      _lastProgressSecond = second;
      _emit({
        'kind': 'nativeProgress',
        'time': second,
        'playing': value.isPlaying,
        'buffering': value.isBuffering,
      });
    }
    if (value.hasError && _error == null) {
      _emit({'kind': 'nativeError'});
      _error =
          'Playback stopped. Retry to refresh the stream, or use the embedded player.';
      _loading = false;
    }
    if (value.isCompleted && !_completedRecorded && _request != null) {
      _completedRecorded = true;
      widget.onCompleted?.call(_request!);
    } else if (value.isPlaying &&
        value.position.inSeconds > 0 &&
        (value.position.inSeconds - _lastCheckpointSecond).abs() >= 15) {
      _checkpoint();
    }
    setState(() {});
  }

  void _checkpoint() {
    final request = _request;
    final value = _controller?.value;
    if (_loading ||
        request == null ||
        value == null ||
        !value.isInitialized ||
        value.hasError ||
        _completedRecorded) {
      return;
    }
    _lastCheckpointSecond = value.position.inSeconds;
    widget.onProgress?.call(
      PlaybackRequest(
        item: request.item,
        server: request.server,
        season: request.safeSeason,
        episode: request.safeEpisode,
        startPosition: value.position,
      ),
    );
  }

  void _emit(Map<String, Object?> event) {
    if (kDebugMode && mounted) {
      _diagnosticCallback?.call({
        'elapsedMs': _clock.elapsedMilliseconds,
        ...event,
      });
    }
  }

  Future<void> _embeddedFallback() async {
    await _release();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => FullscreenLandscapeWebPlayer(
          url: nativeProviderEntry(_entryUrl, _provider).toString(),
          loadAsPage: true,
        ),
      ),
    );
  }

  Future<void> _release() => _releaseFuture ??= _releasePlayback();

  Future<void> _releasePlayback() async {
    _checkpoint();
    ++_generation;
    _hideTimer?.cancel();
    _intent?.dispose();
    final resolver = _resolver;
    final controller = _controller;
    _resolver = null;
    _controller = null;
    controller?.removeListener(_onVideoChanged);
    await resolver?.dispose();
    if (controller != null) {
      try {
        await controller.pause().timeout(const Duration(seconds: 3));
      } catch (_) {}
      await controller.dispose();
    }
  }

  Future<void> _close() async {
    await _release();
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _seek(Duration position) async {
    _intent?.seekTo(position);
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!mounted ||
        _loading ||
        _error != null ||
        _menuOpen ||
        _seekPreview != null ||
        !(_intent?.wantsPlay ?? false) ||
        MediaQuery.of(context).accessibleNavigation) {
      return;
    }
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted &&
          !_menuOpen &&
          _seekPreview == null &&
          (_intent?.wantsPlay ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    if (_panel != null) {
      _closePanel();
      return;
    }
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _togglePlay() {
    final intent = _intent;
    if (intent == null) return;
    intent.setPlaying(!intent.wantsPlay);
    if (!intent.wantsPlay) _checkpoint();
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _openPanel(String panel, {int tab = 0}) {
    _hideTimer?.cancel();
    setState(() {
      _menuOpen = true;
      _controlsVisible = true;
      _panel = panel;
      _trackTab = tab;
    });
  }

  void _closePanel() {
    setState(() {
      _panel = null;
      _menuOpen = false;
    });
    _scheduleHide();
  }

  void _notice(String message) {
    _showFeedback(message);
  }

  Future<void> _selectQuality((String, Uri) selected) async {
    final stream = _stream;
    if (stream == null || _switchingQuality) return;
    _closePanel();
    if (!mounted ||
        stream != _stream ||
        selected.$2.toString() == _controller?.dataSource) {
      return;
    }
    final old = _controller;
    if (old == null) return;
    final position = _intent?.displayedPosition ?? old.value.position;
    final wantsPlay = _intent?.wantsPlay ?? false;
    final generation = _generation;
    _switchingQuality = true;
    _intent?.dispose();
    old.removeListener(_onVideoChanged);
    await old.pause();
    final next = VideoPlayerController.networkUrl(
      selected.$2,
      httpHeaders: stream.headers,
      formatHint: VideoFormat.hls,
      viewType: _videoViewType,
    );
    if (!mounted || generation != _generation) {
      await next.dispose();
      return;
    }
    setState(() {
      _controller = next;
      _loading = true;
      _stage = 'Changing quality…';
    });
    try {
      await next.initialize().timeout(const Duration(seconds: 20));
      await next.setVolume(_volume);
      await next.seekTo(position).timeout(const Duration(seconds: 15));
      if (!mounted || generation != _generation) {
        await next.dispose();
        return;
      }
      _intent = _createIntent(next)..wantsPlay = wantsPlay;
      next.addListener(_onVideoChanged);
      await old.dispose();
      if (wantsPlay) await next.play();
      if (mounted && generation == _generation) {
        setState(() {
          _qualityLabel = selected.$1;
          _loading = false;
        });
      }
    } catch (_) {
      await next.dispose();
      if (mounted && generation == _generation) {
        _controller = old;
        _intent = _createIntent(old)..wantsPlay = wantsPlay;
        old.addListener(_onVideoChanged);
        if (wantsPlay) await old.play();
        setState(() => _loading = false);
        _notice('Quality unavailable; kept previous quality.');
      } else {
        await old.dispose();
      }
    } finally {
      if (!mounted || generation != _generation) await old.dispose();
      _switchingQuality = false;
      if (mounted) _scheduleHide();
    }
  }

  PlaybackIntent _createIntent(VideoPlayerController controller) =>
      PlaybackIntent(
        play: controller.play,
        pause: controller.pause,
        seek: controller.seekTo,
        position: () => controller.value.position,
        duration: () => controller.value.duration,
        onChanged: () {
          if (mounted && _controller == controller) setState(() {});
        },
        onError: (_) {
          if (mounted && _controller == controller) {
            _notice('Playback action timed out. Try again or change source.');
          }
        },
      );

  Future<void> _chooseSubtitles() async {
    final stream = _stream;
    final controller = _controller;
    if (stream == null || controller == null) return;
    _openPanel('tracks');
    setState(() => _tracksLoading = true);
    List<StreamSubtitle> tracks;
    try {
      tracks = await _subtitleRepository.discoverForPlayback(stream, _request);
    } catch (_) {
      tracks = stream.subtitles;
    }
    if (!mounted || _controller != controller) return;
    setState(() {
      _subtitleTracks = tracks;
      _tracksLoading = false;
    });
  }

  Future<void> _selectSubtitle(StreamSubtitle? track) async {
    final stream = _stream;
    final controller = _controller;
    if (stream == null || controller == null) return;
    _closePanel();
    final generation = ++_subtitleGeneration;
    try {
      final captions = track == null
          ? null
          : await _subtitleRepository.load(track, stream);
      if (!mounted ||
          generation != _subtitleGeneration ||
          _controller != controller) {
        return;
      }
      await controller.setClosedCaptionFile(
        captions == null ? null : Future.value(captions),
      );
      if (!mounted ||
          generation != _subtitleGeneration ||
          _controller != controller) {
        return;
      }
      setState(() => _subtitle = track);
    } catch (error) {
      if (!mounted ||
          generation != _subtitleGeneration ||
          _controller != controller) {
        return;
      }
      final message = switch (error) {
        StreamResolutionException() => error.message,
        TimeoutException() => 'Subtitle download timed out. Please try again.',
        FormatException() =>
          'This subtitle file has an unsupported or invalid format.',
        _ => 'Could not load this subtitle track. Please try another track.',
      };
      // Keep signed URLs, query tokens and session headers out of diagnostics.
      debugPrint(
        '[Subtitles] host=${track?.url.host} error=${error.runtimeType}: $message',
      );
      _notice(message);
    }
  }

  void _adjustSubtitleOffset(int milliseconds) {
    final controller = _controller;
    if (controller == null) return;
    final offset = controller.value.captionOffset.inMilliseconds + milliseconds;
    controller.setCaptionOffset(
      Duration(milliseconds: offset.clamp(-60000, 60000)),
    );
    setState(() {});
  }

  Future<void> _selectEpisode(PlayerEpisode selected) async {
    final request = _request;
    if (request == null) return;
    _closePanel();
    if (!mounted ||
        (selected.season == request.safeSeason &&
            selected.number == request.safeEpisode)) {
      return;
    }
    final next = PlaybackRequest(
      item: request.item,
      server: request.server,
      season: selected.season,
      episode: selected.number,
    );
    _request = next;
    _entryUrl = cinesrcPlaybackUrl(
      tmdbId: request.item.remoteId!,
      contentType: request.item.type,
      season: selected.season,
      episode: selected.number,
    );
    ++_subtitleGeneration;
    _subtitle = null;
    _stream = null;
    _episodeName = selected.name;
    ++_episodeLoad;
    widget.onEpisodeChanged?.call(next);
    await _start();
  }

  Future<void> _fullscreen(bool enter) async {
    if (kIsWeb) return;
    await SystemChrome.setPreferredOrientations(
      enter
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : DeviceOrientation.values,
    );
    if (enter && !mounted) return;
    await SystemChrome.setEnabledSystemUIMode(
      enter ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  Future<void> _toggleBrowserFullscreen() async {
    final wasFullscreen = browserIsFullscreen;
    try {
      await toggleBrowserFullscreen();
      if (!mounted) {
        if (!wasFullscreen) await exitBrowserFullscreen();
        return;
      }
      _ownsBrowserFullscreen = !wasFullscreen;
      setState(() => _browserFullscreen = browserIsFullscreen);
      _scheduleHide();
    } catch (_) {
      if (mounted) _notice('Fullscreen is unavailable in this browser.');
    }
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null) return;
    final previous = controller.value.volume;
    if (previous > 0) {
      _volumeBeforeMute = previous;
      _volume = 0;
    } else {
      _volume = _volumeBeforeMute;
    }
    try {
      await controller.setVolume(_volume);
      if (mounted && controller == _controller) _scheduleHide();
    } catch (_) {
      _volume = previous;
      if (mounted) _notice('Could not change volume. Please try again.');
    }
  }

  Future<void> _loadEpisodeName() async {
    final request = _request;
    if (request == null ||
        !isTvPlaybackContent(request.item.type) ||
        request.item.remoteId == null) {
      return;
    }
    final generation = ++_episodeLoad;
    try {
      final episodes = await _episodeRepository.episodes(
        request.item.remoteId!,
        request.safeSeason,
      );
      if (mounted && generation == _episodeLoad) {
        setState(
          () => _episodeName =
              episodes
                  .where((e) => e.number == request.safeEpisode)
                  .firstOrNull
                  ?.name ??
              '',
        );
      }
    } catch (_) {
      /* Numbered title remains usable without catalog access. */
    }
  }

  String get _displayTitle {
    final request = _request;
    if (request == null || !isTvPlaybackContent(request.item.type)) {
      return widget.title;
    }
    final code = PlayerEpisode(
      season: request.safeSeason,
      number: request.safeEpisode,
    ).code;
    return '${widget.title} · $code${_episodeName.isEmpty ? '' : ' · $_episodeName'}';
  }

  Future<void> _readBrightness() async {
    if (kIsWeb) {
      _brightness = 1;
      return;
    }
    try {
      final value = await PlayerPlatform.brightness();
      if (mounted) _brightness = value;
    } catch (_) {}
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    _feedbackTimer?.cancel();
    setState(() => _feedback = message);
    _feedbackTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _feedback = null);
    });
  }

  void _doubleTap() {
    if (_menuOpen || _loading || _controller == null) return;
    final left = (_doubleTapPosition?.dx ?? 0) < _playerSize.width / 2;
    _intent?.skip(Duration(seconds: left ? -10 : 10));
    _showFeedback(left ? '−10 seconds' : '+10 seconds');
    _scheduleHide();
  }

  void _dragStart(DragStartDetails details) {
    _gestureLeft = details.localPosition.dx < _playerSize.width / 2;
    _gestureStartY = details.localPosition.dy;
    _gestureValue = _gestureLeft
        ? _brightness
        : (_controller?.value.volume ?? 1);
    _hideTimer?.cancel();
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_menuOpen || _loading || _controller == null) return;
    final value =
        (_gestureValue +
                (_gestureStartY - details.localPosition.dy) /
                    (_playerSize.height * .65))
            .clamp(0.0, 1.0);
    if (_gestureLeft) {
      _brightness = value;
      _brightnessChanged = true;
      if (!kIsWeb) {
        unawaited(
          PlayerPlatform.setBrightness(value).catchError((Object _) {}),
        );
      }
    } else {
      _volume = value;
      unawaited(_controller!.setVolume(value));
    }
    _showFeedback(
      '${_gestureLeft ? 'Brightness' : 'Volume'} ${(value * 100).round()}%',
    );
  }

  Widget _trackPanel() {
    final stream = _stream;
    final groups = <String, List<StreamSubtitle>>{};
    for (final track in _subtitleTracks) {
      final language = subtitleLanguageLabel(
        track.language.isEmpty ? track.label : track.language,
        track.language,
      );
      groups.putIfAbsent(language, () => []).add(track);
    }
    final languages = groups.keys.toList()..sort();
    final choices = <(String, Uri)>[
      if (stream?.masterUrl != null) ('Auto', stream!.masterUrl!),
      for (final q in stream?.qualities ?? <StreamQuality>[]) (q.label, q.url),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: playerOverlayColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 6),
            child: Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('native-track-tab-$i'),
                      onTap: () {
                        setState(() => _trackTab = i);
                        if (i == 0) unawaited(_chooseSubtitles());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _trackTab == i
                              ? Colors.white12
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          i == 0 ? 'Subtitles' : 'Quality',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _trackTab == i
                                ? playerAccent
                                : Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                PlayerAction(
                  icon: Icons.close,
                  label: 'Close track menu',
                  onTap: _closePanel,
                ),
              ],
            ),
          ),
          if (_trackTab == 0 && _subtitleLanguage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 14, 4),
              child: Row(
                children: [
                  PlayerAction(
                    key: const ValueKey('subtitle-language-back'),
                    icon: Icons.arrow_back,
                    size: 30,
                    iconSize: 18,
                    label: 'All languages',
                    onTap: () => setState(() => _subtitleLanguage = null),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _subtitleLanguage!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              key: PageStorageKey('native-track-list-$_trackTab'),
              controller: _trackTab == 0
                  ? _subtitleScrollController
                  : _qualityScrollController,
              padding: const EdgeInsets.only(bottom: 10),
              children: _trackTab == 0
                  ? [
                      PlayerPanelRow(
                        label: 'Off',
                        selected: _subtitle == null,
                        onTap: () => unawaited(_selectSubtitle(null)),
                      ),
                      if (_subtitle != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PlayerAction(
                              icon: Icons.remove,
                              label: 'Subtitles later by 0.5 seconds',
                              onTap: () => _adjustSubtitleOffset(-500),
                            ),
                            Text(
                              '${((_controller?.value.captionOffset.inMilliseconds ?? 0) / 1000).toStringAsFixed(1)}s',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            PlayerAction(
                              icon: Icons.add,
                              label: 'Subtitles earlier by 0.5 seconds',
                              onTap: () => _adjustSubtitleOffset(500),
                            ),
                            PlayerAction(
                              icon: Icons.restore,
                              label: 'Reset subtitle timing',
                              onTap: () => _adjustSubtitleOffset(
                                -(_controller
                                        ?.value
                                        .captionOffset
                                        .inMilliseconds ??
                                    0),
                              ),
                            ),
                          ],
                        ),
                      if (_tracksLoading)
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'Loading subtitles…',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (_subtitleLanguage == null)
                        for (final language in languages)
                          PlayerPanelRow(
                            key: ValueKey('subtitle-language-$language'),
                            label: '$language (${groups[language]!.length})',
                            selected: false,
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() => _subtitleLanguage = language);
                              if (_subtitleScrollController.hasClients) {
                                _subtitleScrollController.jumpTo(0);
                              }
                            },
                          ),
                      for (final track
                          in groups[_subtitleLanguage] ?? <StreamSubtitle>[])
                        PlayerPanelRow(
                          label:
                              '${subtitleLanguageLabel(track.label, track.language)} · ${track.source}${track.release.isEmpty ? '' : ' · ${track.release}'}',
                          selected: _subtitle?.url == track.url,
                          onTap: () => unawaited(_selectSubtitle(track)),
                        ),
                      if (!_tracksLoading &&
                          (_subtitleTracks.isEmpty ||
                              (_subtitleLanguage == null && languages.isEmpty)))
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'No matching subtitle languages.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ]
                  : [
                      for (final choice in choices)
                        PlayerPanelRow(
                          label: choice.$1,
                          selected: _qualityLabel == choice.$1,
                          onTap: () => unawaited(_selectQuality(choice)),
                        ),
                      if (choices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'No alternate qualities available.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _checkpoint();
      _intent?.setPlaying(false);
    }
  }

  @override
  void dispose() {
    unawaited(_fullscreenSubscription?.cancel());
    if (kIsWeb && _ownsBrowserFullscreen) {
      unawaited(exitBrowserFullscreen().catchError((Object _) {}));
    }
    if (kIsWeb) unawaited(WebStreamResolver.release(_stream));
    _subtitleScrollController.dispose();
    _qualityScrollController.dispose();
    _emit({'kind': 'nativeDisposed', 'hasController': _controller != null});
    WidgetsBinding.instance.removeObserver(this);
    ++_subtitleGeneration;
    _subtitleRepository.dispose();
    if (widget.episodeRepository == null) _episodeRepository.dispose();
    _feedbackTimer?.cancel();
    if (_brightnessChanged && !kIsWeb) {
      unawaited(PlayerPlatform.restoreBrightness());
    }
    unawaited(_release());
    unawaited(_fullscreen(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final value = controller?.value;
    final showControls = _controlsVisible || _loading || _error != null;
    return Scaffold(
      key: ValueKey('native-player-server-$_serverNumber'),
      backgroundColor: Colors.black,
      body: SafeArea(
        key: const ValueKey('native-player-safe-area'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final playbackWidth = constraints.maxWidth;
            final actionSize = playbackWidth < 600 ? 32.0 : 44.0;
            _playerSize = Size(playbackWidth, constraints.maxHeight);
            // Controls follow the safe viewport, independent of video aspect
            // ratio. Only the video below is aspect-fitted.
            return Center(
              child: SizedBox(
                width: playbackWidth,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    if (controller != null)
                      Positioned.fill(
                        child: ClipRect(
                          child: SizedBox.expand(
                            child: FittedBox(
                              key: const ValueKey('native-player-video-fit'),
                              fit: _videoFit,
                              child: SizedBox(
                                width: value!.isInitialized
                                    ? value.size.width
                                    : 16,
                                height: value.isInitialized
                                    ? value.size.height
                                    : 9,
                                child: VideoPlayer(controller),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (kIsWeb && _brightnessChanged)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(
                            color: Colors.black.withValues(
                              alpha: 1 - _brightness,
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: GestureDetector(
                        key: const ValueKey('native-player-tap-surface'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleControls,
                        onDoubleTapDown: (details) =>
                            _doubleTapPosition = details.localPosition,
                        onDoubleTap: _doubleTap,
                        onVerticalDragStart: _dragStart,
                        onVerticalDragUpdate: _dragUpdate,
                        onVerticalDragEnd: (_) => _scheduleHide(),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    if (controller != null &&
                        _subtitle != null &&
                        value!.caption.text.isNotEmpty)
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 16,
                        child: IgnorePointer(
                          child: ClosedCaption(
                            text: plainCaptionText(value.caption.text),
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    if (_loading)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _stage,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    if (_error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                children: [
                                  PlayerAction(
                                    key: const ValueKey('native-player-retry'),
                                    onTap: () => unawaited(
                                      _start(
                                        position:
                                            controller?.value.position ??
                                            Duration.zero,
                                      ),
                                    ),
                                    icon: Icons.refresh,
                                    label: 'Retry',
                                  ),
                                  if (!kIsWeb)
                                    PlayerAction(
                                      key: const ValueKey(
                                        'native-player-embedded-fallback',
                                      ),
                                      onTap: () =>
                                          unawaited(_embeddedFallback()),
                                      label: 'Open embedded player',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (showControls)
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: playerOverlayColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: PlayerAction(
                                key: const ValueKey('native-player-close'),
                                color: Colors.white,
                                size: 32,
                                iconSize: 18,
                                icon: Icons.close,
                                label: 'Close player',
                                onTap: () => unawaited(_close()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _displayTitle,
                                key: const ValueKey('native-player-title'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_request != null &&
                                isTvPlaybackContent(_request!.item.type)) ...[
                              const SizedBox(width: 10),
                              PlayerAction(
                                key: const ValueKey('native-player-episodes'),
                                size: 32,
                                onTap: _loading
                                    ? null
                                    : () => _openPanel('episodes'),
                                label: 'Episodes',
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (showControls &&
                        !_loading &&
                        _error == null &&
                        controller != null &&
                        value!.isInitialized)
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: SafeArea(
                          child: DecoratedBox(
                            key: const ValueKey('native-player-toolbar'),
                            decoration: BoxDecoration(
                              color: playerOverlayColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      PlayerAction(
                                        key: const ValueKey(
                                          'native-player-play-pause',
                                        ),
                                        size: actionSize,
                                        label: (_intent?.wantsPlay ?? false)
                                            ? 'Pause'
                                            : 'Play',
                                        onTap: _togglePlay,
                                        icon:
                                            (_intent?.wantsPlay ??
                                                value.isPlaying)
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      ),
                                      PlayerAction(
                                        key: const ValueKey(
                                          'native-player-rewind',
                                        ),
                                        size: actionSize,
                                        label: 'Rewind 10 seconds',
                                        onTap: () {
                                          _intent?.skip(
                                            const Duration(seconds: -10),
                                          );
                                          _scheduleHide();
                                        },
                                        icon: Icons.replay_10,
                                      ),
                                      PlayerAction(
                                        key: const ValueKey(
                                          'native-player-forward',
                                        ),
                                        size: actionSize,
                                        label: 'Forward 10 seconds',
                                        onTap: () {
                                          _intent?.skip(
                                            const Duration(seconds: 10),
                                          );
                                          _scheduleHide();
                                        },
                                        icon: Icons.forward_10,
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${_time(value.position)} / ${_time(value.duration)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      PlayerAction(
                                        key: const ValueKey(
                                          'native-player-subtitles',
                                        ),
                                        size: actionSize,
                                        label: 'Subtitles',
                                        onTap: _chooseSubtitles,
                                        icon: _subtitle == null
                                            ? Icons.closed_caption_off
                                            : Icons.closed_caption,
                                      ),
                                      PlayerAction(
                                        key: const ValueKey(
                                          'native-player-mute',
                                        ),
                                        size: actionSize,
                                        label: value.volume == 0
                                            ? 'Unmute'
                                            : 'Mute',
                                        child: PlayerControlIcon(
                                          value.volume == 0
                                              ? PlayerControlGlyph.muted
                                              : PlayerControlGlyph.sound,
                                        ),
                                        onTap: () => unawaited(_toggleMute()),
                                      ),
                                      PlayerAction(
                                        key: const ValueKey(
                                          'native-player-quality',
                                        ),
                                        size: actionSize,
                                        onTap: () =>
                                            _openPanel('tracks', tab: 1),
                                        label: 'Quality',
                                        icon: playbackWidth < 600
                                            ? Icons.high_quality
                                            : null,
                                        text: _qualityLabel,
                                        selected: true,
                                      ),
                                      PlayerAction(
                                        key: const ValueKey(
                                          'native-player-fit',
                                        ),
                                        size: actionSize,
                                        label: 'Video sizing',
                                        icon: playbackWidth < 600
                                            ? Icons.aspect_ratio
                                            : null,
                                        text: switch (_videoFit) {
                                          BoxFit.cover => 'Fill',
                                          BoxFit.fill => 'Stretch',
                                          _ => 'Fit',
                                        },
                                        onTap: () {
                                          setState(
                                            () =>
                                                _videoFit = switch (_videoFit) {
                                                  BoxFit.contain =>
                                                    BoxFit.cover,
                                                  BoxFit.cover => BoxFit.fill,
                                                  _ => BoxFit.contain,
                                                },
                                          );
                                          if (playbackWidth < 600) {
                                            _showFeedback(switch (_videoFit) {
                                              BoxFit.cover => 'Fill',
                                              BoxFit.fill => 'Stretch',
                                              _ => 'Fit',
                                            });
                                          }
                                          _scheduleHide();
                                        },
                                      ),
                                      if (kIsWeb)
                                        PlayerAction(
                                          key: const ValueKey(
                                            'web-player-fullscreen',
                                          ),
                                          size: actionSize,
                                          label: _browserFullscreen
                                              ? 'Exit fullscreen'
                                              : 'Enter fullscreen',
                                          child: PlayerControlIcon(
                                            _browserFullscreen
                                                ? PlayerControlGlyph
                                                      .exitFullscreen
                                                : PlayerControlGlyph.fullscreen,
                                          ),
                                          onTap: () => unawaited(
                                            _toggleBrowserFullscreen(),
                                          ),
                                        ),
                                      if (value.isBuffering &&
                                          (_intent?.wantsPlay ?? false))
                                        const Padding(
                                          padding: EdgeInsets.only(left: 12),
                                          child: SizedBox.square(
                                            dimension: 16,
                                            child: CircularProgressIndicator(
                                              key: ValueKey(
                                                'native-playback-buffering',
                                              ),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 32,
                                    child: PlayerSeekBar(
                                      key: const ValueKey('native-player-seek'),
                                      value:
                                          (_seekPreview ??
                                                  (_intent?.displayedPosition ??
                                                          value.position)
                                                      .inMilliseconds
                                                      .toDouble())
                                              .clamp(
                                                0,
                                                value.duration.inMilliseconds,
                                              )
                                              .toDouble(),
                                      max: value.duration.inMilliseconds > 0
                                          ? value.duration.inMilliseconds
                                                .toDouble()
                                          : 1,
                                      onChanged: (position) {
                                        _hideTimer?.cancel();
                                        setState(() => _seekPreview = position);
                                      },
                                      onChangeEnd: (position) {
                                        setState(() => _seekPreview = null);
                                        unawaited(
                                          _seek(
                                            Duration(
                                              milliseconds: position.round(),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_feedback != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: playerOverlayColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _feedback!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_panel != null)
                      Positioned(
                        key: const ValueKey('native-player-panel'),
                        top: MediaQuery.paddingOf(context).top + 20,
                        bottom: 12 + MediaQuery.paddingOf(context).bottom,
                        right: 16 + MediaQuery.paddingOf(context).right,
                        width: (playbackWidth * .34).clamp(260.0, 350.0),
                        child: _panel == 'tracks'
                            ? _trackPanel()
                            : PlayerEpisodePanel(
                                key: ValueKey(
                                  'episode-panel-${_request?.item.remoteId}',
                                ),
                                repository: _episodeRepository,
                                seriesId: _request!.item.remoteId!,
                                season: _request!.safeSeason,
                                episode: _request!.safeEpisode,
                                onSelect: (episode) =>
                                    unawaited(_selectEpisode(episode)),
                                onClose: _closePanel,
                              ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _time(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
}

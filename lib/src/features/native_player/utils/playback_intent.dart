import 'dart:async';

/// Serializes native operations. A later pause or seek always wins over an
/// earlier operation completing; skips accumulate against the pending target.
class PlaybackIntent {
  PlaybackIntent({
    required this.play,
    required this.pause,
    required this.seek,
    required this.position,
    required this.duration,
    required this.onChanged,
    required this.onError,
  });

  final Future<void> Function() play;
  final Future<void> Function() pause;
  final Future<void> Function(Duration) seek;
  final Duration Function() position;
  final Duration Function() duration;
  final void Function() onChanged;
  final void Function(Object) onError;
  bool wantsPlay = true;
  bool _disposed = false;
  bool _running = false;
  bool _intentDirty = false;
  Duration? _pendingSeek;
  Duration? _activeSeek;
  bool get seeking => _pendingSeek != null || _activeSeek != null;
  Duration get displayedPosition => _pendingSeek ?? _activeSeek ?? position();

  void setPlaying(bool value) {
    if (_disposed) return;
    wantsPlay = value;
    _intentDirty = true;
    onChanged();
    // Pause immediately even if a native seek is waiting for network data.
    if (!value) {
      unawaited(
        pause().catchError((Object e) {
          if (!_disposed) onError(e);
        }),
      );
    }
    unawaited(_drain());
  }

  void seekTo(Duration target) {
    if (_disposed) return;
    _pendingSeek = Duration(
      milliseconds: target.inMilliseconds.clamp(0, duration().inMilliseconds),
    );
    onChanged();
    unawaited(_drain());
  }

  void skip(Duration delta) => seekTo(displayedPosition + delta);

  Future<void> _drain() async {
    if (_running || _disposed) return;
    _running = true;
    try {
      while (!_disposed && (_pendingSeek != null || _intentDirty)) {
        if (_pendingSeek != null) {
          final target = _activeSeek = _pendingSeek;
          _pendingSeek = null;
          // Do not pause/resume around every seek: preserve native buffered data.
          await seek(target!).timeout(const Duration(seconds: 15));
          _activeSeek = null;
          _intentDirty = true;
        } else {
          _intentDirty = false;
          await (wantsPlay ? play() : pause()).timeout(
            const Duration(seconds: 5),
          );
        }
      }
    } catch (error) {
      _pendingSeek = null;
      _activeSeek = null;
      _intentDirty = false;
      if (!_disposed) onError(error);
    } finally {
      _running = false;
      if (!_disposed) onChanged();
    }
  }

  void dispose() {
    _disposed = true;
    _pendingSeek = null;
  }
}

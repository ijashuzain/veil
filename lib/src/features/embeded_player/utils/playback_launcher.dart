import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/providers/ad_providers.dart';
import 'package:veil/src/features/playback_history/view_model/playback_history_view_model.dart';
import 'package:veil/src/features/embeded_player/utils/compact_web_player_policy.dart';
import 'package:veil/src/features/embeded_player/utils/external_player_launcher.dart';
import 'package:veil/src/features/embeded_player/utils/playback_target.dart';
import 'package:veil/src/features/embeded_player/view/player.dart';
import 'package:veil/src/shared/models/playback_request.dart';
import 'package:veil/src/features/native_player/view/native_player_view.dart';
import 'package:veil/src/features/playback_history/models/playback_history_entry.dart';

typedef PlaybackRequestLauncher =
    Future<bool> Function(BuildContext context, PlaybackRequest request);

bool _launchingNative = false;

Future<bool> launchPlaybackRequest(
  BuildContext context,
  PlaybackRequest request,
) async {
  if (kIsWeb && request.server == PlaybackServer.six) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Player 2 is unavailable on web. Please select Player 1.',
        ),
      ),
    );
    return false;
  }
  final native = playbackTargetFor(request)?.nativePlayback ?? false;
  if (!native) return _launchPlaybackRequest(context, request);
  if (_launchingNative) return false;
  _launchingNative = true;
  try {
    await ProviderScope.containerOf(
      context,
      listen: false,
    ).read(playbackInterstitialProvider).showIfEligible();
    if (!context.mounted) return false;
    return await _launchPlaybackRequest(context, request);
  } finally {
    _launchingNative = false;
  }
}

Future<bool> _launchPlaybackRequest(
  BuildContext context,
  PlaybackRequest request,
) async {
  final target = playbackTargetFor(request);
  if (target == null) return false;

  if (target.nativePlayback) {
    Future<void> saveProgress(PlaybackRequest progress) async {
      if (!context.mounted) return;
      try {
        await ProviderScope.containerOf(
          context,
          listen: false,
        ).read(playbackHistoryViewModelProvider.notifier).record(progress);
      } catch (error) {
        debugPrint('Cannot save playback progress: ${error.runtimeType}');
      }
    }

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => NativePlayerView(
          entryUrl: target.url,
          title: request.item.title,
          request: request,
          onProgress: saveProgress,
          onEpisodeChanged: saveProgress,
          onCompleted: (episode) async {
            if (!context.mounted) return;
            try {
              await ProviderScope.containerOf(context, listen: false)
                  .read(playbackHistoryViewModelProvider.notifier)
                  .remove(
                    PlaybackHistoryEntry.fromRequest(
                      episode,
                      DateTime.now(),
                    ).entryKey,
                  );
            } catch (error) {
              debugPrint(
                'Cannot finish playback history: ${error.runtimeType}',
              );
            }
          },
        ),
      ),
    );
    return true;
  }

  final viewportWidth = MediaQuery.sizeOf(context).width;
  if (kIsWeb && target.externalOnWeb) {
    return openExternalPlayerDirect(target.url);
  }
  if (!target.forceEmbedded &&
      shouldOpenPlayerExternally(isWeb: kIsWeb, viewportWidth: viewportWidth)) {
    return openExternalPlayerCandidates([target.url, ...target.fallbackUrls]);
  }

  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => FullscreenLandscapeWebPlayer(
        url: target.url.toString(),
        fallbackUrls: target.fallbackUrls,
        loadAsPage: target.loadAsPage,
      ),
    ),
  );
  return true;
}

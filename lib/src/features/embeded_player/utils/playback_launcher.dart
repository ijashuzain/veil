import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:veil/src/features/embeded_player/utils/compact_web_player_policy.dart';
import 'package:veil/src/features/embeded_player/utils/external_player_launcher.dart';
import 'package:veil/src/features/embeded_player/utils/playback_target.dart';
import 'package:veil/src/features/embeded_player/view/player.dart';
import 'package:veil/src/shared/models/playback_request.dart';

typedef PlaybackRequestLauncher =
    Future<bool> Function(BuildContext context, PlaybackRequest request);

Future<bool> launchPlaybackRequest(
  BuildContext context,
  PlaybackRequest request,
) async {
  final target = playbackTargetFor(request);
  if (target == null) return false;

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

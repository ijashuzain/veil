import 'dart:async';
import 'package:flutter/material.dart';
import 'package:veil/src/features/detail/view/detail_view.dart';
import 'package:veil/src/features/embeded_player/utils/playback_launcher.dart';
import 'package:veil/src/features/embeded_player/utils/playback_target.dart';
import 'package:veil/src/shared/models/playback_request.dart';

/// Continue Watching enters playback immediately, with the title's detail page
/// underneath it. Closing playback never pushes a new page or returns to Home.
Future<bool> launchHistoryPlayback(
  BuildContext context,
  PlaybackRequest request, {
  PlaybackRequestLauncher playerLauncher = launchPlaybackRequest,
}) async {
  if (request.server != PlaybackServer.five &&
      request.server != PlaybackServer.six) {
    return false;
  }
  if (playbackTargetFor(request) == null) return false;
  final navigator = Navigator.of(context, rootNavigator: true);
  final detail = PageRouteBuilder<void>(
    settings: const RouteSettings(name: 'continue-watching-detail'),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, _, _) =>
        DetailView(item: request.item, onBack: () => navigator.maybePop()),
  );
  unawaited(navigator.push(detail));
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted || !navigator.mounted || !detail.isCurrent) {
    if (navigator.mounted && detail.isActive) navigator.removeRoute(detail);
    return false;
  }
  try {
    final opened = await playerLauncher(context, request);
    if (!opened && navigator.mounted && detail.isActive) {
      navigator.removeRoute(detail);
    }
    return opened;
  } catch (_) {
    if (navigator.mounted && detail.isActive) navigator.removeRoute(detail);
    rethrow;
  }
}

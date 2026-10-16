import 'package:flutter/material.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/utils/web_video_setup.dart';
import 'package:veil/src/features/native_player/view/native_player_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureWebVideo();
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: NativePlayerView(
        entryUrl: Uri.parse('https://cinesrc.st/embed/movie/1'),
        title: 'Web player smoke test',
        resolverFactory: _Fixture.new,
      ),
    ),
  );
}

class _Fixture implements StreamResolver {
  @override
  Future<ResolvedStream> resolve(Uri entry) async => ResolvedStream(
    url: Uri.parse('https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8'),
    format: NativeStreamFormat.hls,
    headers: {},
    resolvedAt: DateTime.now(),
    subtitles: [
      StreamSubtitle(
        url: Uri.base.resolve('captions.vtt'),
        label: 'English',
        language: 'en',
      ),
    ],
  );
  @override
  Future<void> dispose() async {}
}

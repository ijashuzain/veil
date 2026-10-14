import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/repository/provider_stream_resolver.dart';
import 'package:veil/src/features/native_player/repository/vidzee_stream_resolver.dart';

void main() {
  test('separate native providers keep episode identity', () {
    final identity = Uri.parse('https://cinesrc.st/embed/tv/94605?s=2&e=3');
    expect(
      nativeProviderEntry(identity, NativeProvider.vidsrc).toString(),
      'https://vsembed.ru/embed/tv/94605/2/3',
    );
    expect(nativeProviderEntry(identity, NativeProvider.cinesrc), identity);
  });
  test(
    'failed provider is disposed and never switches to another provider',
    () async {
      final used = <NativeProvider>[];
      final failing = _FailingResolver();
      final resolver = ProviderStreamResolver(
        providers: [NativeProvider.vidsrc],
        factory: (provider) {
          used.add(provider);
          return failing;
        },
      );
      await expectLater(
        resolver.resolve(Uri.parse('https://cinesrc.st/embed/movie/123')),
        throwsA(isA<StreamResolutionException>()),
      );
      expect(used, [NativeProvider.vidsrc]);
      expect(failing.closed, isTrue);
    },
  );
  test(
    'Vidzee rejects a successful HTTP response containing invalid HLS',
    () async {
      final resolver = VidzeeStreamResolver(
        client: MockClient((request) async {
          if (request.url.path == '/resolve') {
            return http.Response(
              '{"success":true,"sources":[{"url":"https://api.vz.raphsm4.dev/proxy?url=x"}]}',
              200,
            );
          }
          return http.Response('https://proxy.test/not-a-playlist', 200);
        }),
      );
      await expectLater(
        resolver.resolve(Uri.parse('https://cinesrc.st/embed/movie/123')),
        throwsA(isA<StreamResolutionException>()),
      );
      await resolver.dispose();
    },
  );
}

class _FailingResolver implements StreamResolver {
  bool closed = false;
  @override
  Future<ResolvedStream> resolve(Uri url) async =>
      throw const StreamResolutionException('unavailable');
  @override
  Future<void> dispose() async {
    closed = true;
  }
}

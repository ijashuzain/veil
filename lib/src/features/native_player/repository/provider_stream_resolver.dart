import 'package:veil/src/features/native_player/models/resolved_stream.dart';
import 'package:veil/src/features/native_player/repository/cinesrc_stream_resolver.dart';
import 'package:veil/src/features/native_player/repository/vidzee_stream_resolver.dart';

enum NativeProvider { cinesrc, vidsrc, cinejoy, vidlink, vidzee }

Uri nativeProviderEntry(Uri identity, NativeProvider provider) {
  final parts = identity.pathSegments;
  if (parts.length < 3) {
    throw const StreamResolutionException('Missing content identity.');
  }
  final tv = parts[1] == 'tv';
  final id = parts[2];
  final season = identity.queryParameters['s'] ?? '1';
  final episode = identity.queryParameters['e'] ?? '1';
  return switch (provider) {
    NativeProvider.cinesrc || NativeProvider.vidzee => identity,
    NativeProvider.vidsrc => Uri.https(
      'vsembed.ru',
      tv ? '/embed/tv/$id/$season/$episode' : '/embed/movie/$id',
    ),
    NativeProvider.cinejoy => Uri.https(
      'cinejoy.pk',
      tv ? '/watch/tv/$id/$season/$episode' : '/watch/movie/$id',
    ),
    NativeProvider.vidlink => Uri.https(
      'vidlink.pro',
      tv ? '/tv/$id/$season/$episode' : '/movie/$id',
      {'player': 'jw'},
    ),
  };
}

/// One explicitly selected provider per native server. Never switches providers.
class ProviderStreamResolver implements StreamResolver {
  ProviderStreamResolver({
    this.providers = const [NativeProvider.cinesrc],
    this.onAttempt,
    this.factory,
  }) : assert(providers.length == 1);
  final List<NativeProvider> providers;
  final void Function(NativeProvider)? onAttempt;
  final StreamResolver Function(NativeProvider)? factory;
  StreamResolver? _active;
  bool _disposed = false;
  @override
  Future<ResolvedStream> resolve(Uri entryUrl) async {
    for (final provider in providers) {
      if (_disposed) {
        throw const StreamResolutionException('Resolution cancelled.');
      }
      onAttempt?.call(provider);
      final resolver = _active =
          factory?.call(provider) ??
          (provider == NativeProvider.vidzee
              ? VidzeeStreamResolver()
              : CineSrcStreamResolver(provider: provider.name));
      try {
        return await resolver.resolve(nativeProviderEntry(entryUrl, provider));
      } catch (_) {
        if (_disposed) {
          throw const StreamResolutionException('Resolution cancelled.');
        }
      } finally {
        await resolver.dispose();
        if (_active == resolver) _active = null;
      }
    }
    throw const StreamResolutionException(
      'No native source is available. Try the embedded player.',
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _active?.dispose();
  }
}

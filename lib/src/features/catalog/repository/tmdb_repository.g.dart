// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tmdbRepository)
final tmdbRepositoryProvider = TmdbRepositoryProvider._();

final class TmdbRepositoryProvider
    extends $FunctionalProvider<TmdbRepository, TmdbRepository, TmdbRepository>
    with $Provider<TmdbRepository> {
  TmdbRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tmdbRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tmdbRepositoryHash();

  @$internal
  @override
  $ProviderElement<TmdbRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TmdbRepository create(Ref ref) {
    return tmdbRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TmdbRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TmdbRepository>(value),
    );
  }
}

String _$tmdbRepositoryHash() => r'5935f4e01756f6e9e3fd446fa2807375b8df18e3';

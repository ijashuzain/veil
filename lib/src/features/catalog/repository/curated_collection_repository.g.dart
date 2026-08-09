// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curated_collection_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(curatedCollectionRepository)
final curatedCollectionRepositoryProvider =
    CuratedCollectionRepositoryProvider._();

final class CuratedCollectionRepositoryProvider
    extends
        $FunctionalProvider<
          CuratedCollectionRepository,
          CuratedCollectionRepository,
          CuratedCollectionRepository
        >
    with $Provider<CuratedCollectionRepository> {
  CuratedCollectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'curatedCollectionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$curatedCollectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<CuratedCollectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CuratedCollectionRepository create(Ref ref) {
    return curatedCollectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CuratedCollectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CuratedCollectionRepository>(value),
    );
  }
}

String _$curatedCollectionRepositoryHash() =>
    r'f1bef600033b3668894ffecac2d01dcce2ffaef0';

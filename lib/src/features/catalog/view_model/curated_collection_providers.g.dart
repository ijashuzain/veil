// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curated_collection_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(curatedCollections)
final curatedCollectionsProvider = CuratedCollectionsProvider._();

final class CuratedCollectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CuratedCollection>>,
          List<CuratedCollection>,
          FutureOr<List<CuratedCollection>>
        >
    with
        $FutureModifier<List<CuratedCollection>>,
        $FutureProvider<List<CuratedCollection>> {
  CuratedCollectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'curatedCollectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$curatedCollectionsHash();

  @$internal
  @override
  $FutureProviderElement<List<CuratedCollection>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CuratedCollection>> create(Ref ref) {
    return curatedCollections(ref);
  }
}

String _$curatedCollectionsHash() =>
    r'01537c69057cfc1fbacc88179f3e960a1e7a7ef4';

@ProviderFor(curatedCollectionItems)
final curatedCollectionItemsProvider = CuratedCollectionItemsFamily._();

final class CuratedCollectionItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ContentItem>>,
          List<ContentItem>,
          FutureOr<List<ContentItem>>
        >
    with
        $FutureModifier<List<ContentItem>>,
        $FutureProvider<List<ContentItem>> {
  CuratedCollectionItemsProvider._({
    required CuratedCollectionItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'curatedCollectionItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$curatedCollectionItemsHash();

  @override
  String toString() {
    return r'curatedCollectionItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ContentItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ContentItem>> create(Ref ref) {
    final argument = this.argument as String;
    return curatedCollectionItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CuratedCollectionItemsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$curatedCollectionItemsHash() =>
    r'94761120f770c2f95bd350b137f30d0b2f82c4d4';

final class CuratedCollectionItemsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ContentItem>>, String> {
  CuratedCollectionItemsFamily._()
    : super(
        retry: null,
        name: r'curatedCollectionItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CuratedCollectionItemsProvider call(String collectionId) =>
      CuratedCollectionItemsProvider._(argument: collectionId, from: this);

  @override
  String toString() => r'curatedCollectionItemsProvider';
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchProviders)
final watchProvidersProvider = WatchProvidersProvider._();

final class WatchProvidersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TmdbWatchProvider>>,
          List<TmdbWatchProvider>,
          FutureOr<List<TmdbWatchProvider>>
        >
    with
        $FutureModifier<List<TmdbWatchProvider>>,
        $FutureProvider<List<TmdbWatchProvider>> {
  WatchProvidersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchProvidersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchProvidersHash();

  @$internal
  @override
  $FutureProviderElement<List<TmdbWatchProvider>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TmdbWatchProvider>> create(Ref ref) {
    return watchProviders(ref);
  }
}

String _$watchProvidersHash() => r'24c868aa1f1cb0d3930eb541ad64d93ba1e04218';

@ProviderFor(ProviderCatalog)
final providerCatalogProvider = ProviderCatalogFamily._();

final class ProviderCatalogProvider
    extends $NotifierProvider<ProviderCatalog, ProviderCatalogState> {
  ProviderCatalogProvider._({
    required ProviderCatalogFamily super.from,
    required (int, String) super.argument,
  }) : super(
         retry: null,
         name: r'providerCatalogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$providerCatalogHash();

  @override
  String toString() {
    return r'providerCatalogProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ProviderCatalog create() => ProviderCatalog();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProviderCatalogState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProviderCatalogState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProviderCatalogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$providerCatalogHash() => r'4374d112e35edacaae0166527c652947a84d9af9';

final class ProviderCatalogFamily extends $Family
    with
        $ClassFamilyOverride<
          ProviderCatalog,
          ProviderCatalogState,
          ProviderCatalogState,
          ProviderCatalogState,
          (int, String)
        > {
  ProviderCatalogFamily._()
    : super(
        retry: null,
        name: r'providerCatalogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProviderCatalogProvider call(int providerId, String mediaType) =>
      ProviderCatalogProvider._(argument: (providerId, mediaType), from: this);

  @override
  String toString() => r'providerCatalogProvider';
}

abstract class _$ProviderCatalog extends $Notifier<ProviderCatalogState> {
  late final _$args = ref.$arg as (int, String);
  int get providerId => _$args.$1;
  String get mediaType => _$args.$2;

  ProviderCatalogState build(int providerId, String mediaType);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProviderCatalogState, ProviderCatalogState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProviderCatalogState, ProviderCatalogState>,
              ProviderCatalogState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchViewModel)
final searchViewModelProvider = SearchViewModelProvider._();

final class SearchViewModelProvider
    extends $NotifierProvider<SearchViewModel, SearchViewState> {
  SearchViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchViewModelHash();

  @$internal
  @override
  SearchViewModel create() => SearchViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchViewState>(value),
    );
  }
}

String _$searchViewModelHash() => r'66bb83a2e2c37f37b595358a2dc7ebac47e1edd6';

abstract class _$SearchViewModel extends $Notifier<SearchViewState> {
  SearchViewState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchViewState, SearchViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchViewState, SearchViewState>,
              SearchViewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

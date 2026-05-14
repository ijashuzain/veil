// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DetailViewModel)
final detailViewModelProvider = DetailViewModelFamily._();

final class DetailViewModelProvider
    extends $NotifierProvider<DetailViewModel, DetailViewState> {
  DetailViewModelProvider._({
    required DetailViewModelFamily super.from,
    required ContentItem super.argument,
  }) : super(
         retry: null,
         name: r'detailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$detailViewModelHash();

  @override
  String toString() {
    return r'detailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DetailViewModel create() => DetailViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DetailViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DetailViewState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DetailViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$detailViewModelHash() => r'2d2d5256fbbae4901cc1e1505c84cb5474ad8adf';

final class DetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          DetailViewModel,
          DetailViewState,
          DetailViewState,
          DetailViewState,
          ContentItem
        > {
  DetailViewModelFamily._()
    : super(
        retry: null,
        name: r'detailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DetailViewModelProvider call(ContentItem item) =>
      DetailViewModelProvider._(argument: item, from: this);

  @override
  String toString() => r'detailViewModelProvider';
}

abstract class _$DetailViewModel extends $Notifier<DetailViewState> {
  late final _$args = ref.$arg as ContentItem;
  ContentItem get item => _$args;

  DetailViewState build(ContentItem item);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DetailViewState, DetailViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DetailViewState, DetailViewState>,
              DetailViewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

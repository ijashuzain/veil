// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_library_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SocialLibraryViewModel)
final socialLibraryViewModelProvider = SocialLibraryViewModelProvider._();

final class SocialLibraryViewModelProvider
    extends $NotifierProvider<SocialLibraryViewModel, SocialLibraryViewState> {
  SocialLibraryViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialLibraryViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialLibraryViewModelHash();

  @$internal
  @override
  SocialLibraryViewModel create() => SocialLibraryViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialLibraryViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialLibraryViewState>(value),
    );
  }
}

String _$socialLibraryViewModelHash() =>
    r'fe17474edac37664a090c609ff0f0664604600eb';

abstract class _$SocialLibraryViewModel
    extends $Notifier<SocialLibraryViewState> {
  SocialLibraryViewState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<SocialLibraryViewState, SocialLibraryViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SocialLibraryViewState, SocialLibraryViewState>,
              SocialLibraryViewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

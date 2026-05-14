// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alerts_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AlertsViewModel)
final alertsViewModelProvider = AlertsViewModelProvider._();

final class AlertsViewModelProvider
    extends $NotifierProvider<AlertsViewModel, AlertsViewState> {
  AlertsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertsViewModelHash();

  @$internal
  @override
  AlertsViewModel create() => AlertsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertsViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertsViewState>(value),
    );
  }
}

String _$alertsViewModelHash() => r'4066f1ff894378be8a3996f472fc8f258864802f';

abstract class _$AlertsViewModel extends $Notifier<AlertsViewState> {
  AlertsViewState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AlertsViewState, AlertsViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AlertsViewState, AlertsViewState>,
              AlertsViewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

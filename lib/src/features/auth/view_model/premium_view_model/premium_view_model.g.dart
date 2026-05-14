// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'premium_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentUserIsPremium)
final currentUserIsPremiumProvider = CurrentUserIsPremiumProvider._();

final class CurrentUserIsPremiumProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  CurrentUserIsPremiumProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIsPremiumProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIsPremiumHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return currentUserIsPremium(ref);
  }
}

String _$currentUserIsPremiumHash() =>
    r'ae27004b9322dbfbfd2d6b7b1a35a8b0f1961659';

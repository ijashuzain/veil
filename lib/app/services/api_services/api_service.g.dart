// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(api)
final apiProvider = ApiProvider._();

final class ApiProvider extends $FunctionalProvider<Api, Api, Api>
    with $Provider<Api> {
  ApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiHash();

  @$internal
  @override
  $ProviderElement<Api> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Api create(Ref ref) {
    return api(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Api value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Api>(value),
    );
  }
}

String _$apiHash() => r'3d7b20b8f493940e71358108e14abece3deea5e8';

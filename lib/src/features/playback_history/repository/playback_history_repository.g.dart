// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_history_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playbackHistoryRepository)
final playbackHistoryRepositoryProvider = PlaybackHistoryRepositoryProvider._();

final class PlaybackHistoryRepositoryProvider
    extends
        $FunctionalProvider<
          PlaybackHistoryRepository,
          PlaybackHistoryRepository,
          PlaybackHistoryRepository
        >
    with $Provider<PlaybackHistoryRepository> {
  PlaybackHistoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playbackHistoryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playbackHistoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaybackHistoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaybackHistoryRepository create(Ref ref) {
    return playbackHistoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaybackHistoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaybackHistoryRepository>(value),
    );
  }
}

String _$playbackHistoryRepositoryHash() =>
    r'4f34f1a7c8b33b95883d0a0dae91b5b6ff1363af';

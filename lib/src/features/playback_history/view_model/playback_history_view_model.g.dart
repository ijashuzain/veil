// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_history_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlaybackHistoryViewModel)
final playbackHistoryViewModelProvider = PlaybackHistoryViewModelProvider._();

final class PlaybackHistoryViewModelProvider
    extends
        $NotifierProvider<
          PlaybackHistoryViewModel,
          List<PlaybackHistoryEntry>
        > {
  PlaybackHistoryViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playbackHistoryViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playbackHistoryViewModelHash();

  @$internal
  @override
  PlaybackHistoryViewModel create() => PlaybackHistoryViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PlaybackHistoryEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PlaybackHistoryEntry>>(value),
    );
  }
}

String _$playbackHistoryViewModelHash() =>
    r'114e7d8f0c742263ac25a296da0d4494028bd4ce';

abstract class _$PlaybackHistoryViewModel
    extends $Notifier<List<PlaybackHistoryEntry>> {
  List<PlaybackHistoryEntry> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<List<PlaybackHistoryEntry>, List<PlaybackHistoryEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<PlaybackHistoryEntry>,
                List<PlaybackHistoryEntry>
              >,
              List<PlaybackHistoryEntry>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

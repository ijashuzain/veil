import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/playback_history/models/playback_history_entry.dart';
import 'package:veil/src/features/playback_history/repository/playback_history_repository.dart';
import 'package:veil/src/shared/models/playback_request.dart';

part 'playback_history_view_model.g.dart';

@riverpod
class PlaybackHistoryViewModel extends _$PlaybackHistoryViewModel {
  @override
  List<PlaybackHistoryEntry> build() {
    final userId = ref.watch(authViewModelProvider).user?.id;
    if (userId == null || userId.isEmpty) return const [];
    return ref.watch(playbackHistoryRepositoryProvider).load(userId);
  }

  Future<void> record(PlaybackRequest request) async {
    final userId = ref.read(authViewModelProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    final entries = await ref
        .read(playbackHistoryRepositoryProvider)
        .record(userId, request);
    if (ref.read(authViewModelProvider).user?.id == userId) state = entries;
  }

  Future<void> remove(String entryKey) async {
    final userId = ref.read(authViewModelProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    final entries = await ref
        .read(playbackHistoryRepositoryProvider)
        .remove(userId, entryKey);
    if (ref.read(authViewModelProvider).user?.id == userId) state = entries;
  }

  Future<void> clear() async {
    final userId = ref.read(authViewModelProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    await ref.read(playbackHistoryRepositoryProvider).clear(userId);
    if (ref.read(authViewModelProvider).user?.id == userId) state = const [];
  }
}

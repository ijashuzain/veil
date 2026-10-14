import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/app/services/local_storage_services/local_storage_services.dart';
import 'package:veil/src/features/playback_history/models/playback_history_entry.dart';
import 'package:veil/src/shared/models/playback_request.dart';

part 'playback_history_repository.g.dart';

@riverpod
PlaybackHistoryRepository playbackHistoryRepository(Ref ref) {
  return PlaybackHistoryRepository();
}

class PlaybackHistoryRepository {
  PlaybackHistoryRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const maxEntries = 20;
  static const _storagePrefix = 'veil.playback_history.v1.';

  final DateTime Function() _now;
  Future<void> _writes = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static String storageKeyFor(String userId) => '$_storagePrefix$userId';

  List<PlaybackHistoryEntry> load(String userId) {
    final raw = LocalStorage.getString(storageKeyFor(userId));
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final parsed = <({PlaybackHistoryEntry entry, int index})>[];
      for (var index = 0; index < decoded.length; index += 1) {
        final row = decoded[index];
        if (row is! Map) continue;
        try {
          parsed.add((
            entry: PlaybackHistoryEntry.fromJson(
              Map<String, dynamic>.from(row),
            ),
            index: index,
          ));
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }
      parsed.sort((left, right) {
        final byTime = right.entry.startedAt.compareTo(left.entry.startedAt);
        return byTime != 0 ? byTime : left.index.compareTo(right.index);
      });

      final keys = <String>{};
      return [
        for (final row in parsed)
          if (row.entry.canResume && keys.add(row.entry.contentKey)) row.entry,
      ].take(maxEntries).toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<List<PlaybackHistoryEntry>> record(
    String userId,
    PlaybackRequest request,
  ) => _serialize(() async {
    final tmdbId = request.item.remoteId;
    if (request.server != PlaybackServer.five &&
        request.server != PlaybackServer.six) {
      return load(userId);
    }
    if (tmdbId == null || tmdbId <= 0) return load(userId);

    final entry = PlaybackHistoryEntry.fromRequest(request, _now());
    final entries = [
      entry,
      for (final existing in load(userId))
        if (existing.entryKey != entry.entryKey) existing,
    ].take(maxEntries).toList(growable: false);
    await _save(userId, entries);
    return entries;
  });

  Future<List<PlaybackHistoryEntry>> remove(String userId, String entryKey) =>
      _serialize(() async {
        final entries = load(
          userId,
        ).where((entry) => entry.entryKey != entryKey).toList(growable: false);
        await _save(userId, entries);
        return entries;
      });

  Future<void> clear(String userId) => _serialize(() async {
    await LocalStorage.remove(storageKeyFor(userId));
  });

  Future<void> _save(String userId, List<PlaybackHistoryEntry> entries) async {
    await LocalStorage.setString(
      storageKeyFor(userId),
      jsonEncode([for (final entry in entries) entry.toJson()]),
    );
  }
}

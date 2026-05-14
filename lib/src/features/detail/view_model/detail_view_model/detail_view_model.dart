import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/catalog/models/content_detail/content_detail.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'detail_view_model.freezed.dart';
part 'detail_view_model.g.dart';

@freezed
abstract class DetailViewState with _$DetailViewState {
  const DetailViewState._();

  const factory DetailViewState({
    required ContentDetail detail,
    int? trendingRank,
    @Default(Status.initial()) Status loadStatus,
  }) = _DetailViewState;
}

@riverpod
class DetailViewModel extends _$DetailViewModel {
  @override
  DetailViewState build(ContentItem item) {
    Future.microtask(load);
    return DetailViewState(detail: ContentDetail.fallback(item));
  }

  Future<void> load() async {
    if (state.loadStatus is StatusLoading) return;

    try {
      state = state.copyWith(loadStatus: const Status.loading());
      final repository = ref.read(tmdbRepositoryProvider);
      final detail = await repository.detail(item);
      final trendingRank = await _loadTrendingRank(repository, detail.item);
      state = state.copyWith(
        detail: detail,
        trendingRank: trendingRank,
        loadStatus: const Status.success(),
      );
    } catch (error) {
      state = state.copyWith(loadStatus: Status.failure(error.toString()));
    }
  }

  Future<int?> _loadTrendingRank(
    TmdbRepository repository,
    ContentItem item,
  ) async {
    try {
      final trending = await repository.trending();
      return _rankInTrending(item, trending);
    } catch (_) {
      return null;
    }
  }
}

int? _rankInTrending(ContentItem item, List<ContentItem> trending) {
  final remoteId = item.remoteId;
  if (remoteId == null) return null;
  final mediaType = _mediaType(item);
  final index = trending.indexWhere(
    (candidate) =>
        candidate.remoteId == remoteId && _mediaType(candidate) == mediaType,
  );
  return index == -1 ? null : index + 1;
}

String _mediaType(ContentItem item) {
  if (item.mediaType == 'tv') return 'tv';
  if (item.type.toLowerCase().contains('tv')) return 'tv';
  return 'movie';
}

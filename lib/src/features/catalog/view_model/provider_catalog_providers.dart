import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/catalog/models/tmdb_watch_provider.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/shared/models/content_item.dart';

part 'provider_catalog_providers.g.dart';

@riverpod
Future<List<TmdbWatchProvider>> watchProviders(Ref ref) {
  return ref.watch(tmdbRepositoryProvider).watchProviders();
}

class ProviderCatalogState {
  const ProviderCatalogState({
    this.items = const [],
    this.page = 0,
    this.canLoadMore = true,
    this.isLoadingMore = false,
    this.loadStatus = const Status.initial(),
    this.loadMoreError = '',
  });

  final List<ContentItem> items;
  final int page;
  final bool canLoadMore;
  final bool isLoadingMore;
  final Status loadStatus;
  final String loadMoreError;

  ProviderCatalogState copyWith({
    List<ContentItem>? items,
    int? page,
    bool? canLoadMore,
    bool? isLoadingMore,
    Status? loadStatus,
    String? loadMoreError,
  }) {
    return ProviderCatalogState(
      items: items ?? this.items,
      page: page ?? this.page,
      canLoadMore: canLoadMore ?? this.canLoadMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadStatus: loadStatus ?? this.loadStatus,
      loadMoreError: loadMoreError ?? this.loadMoreError,
    );
  }
}

@riverpod
class ProviderCatalog extends _$ProviderCatalog {
  late int _providerId;
  late String _mediaType;
  bool _isLoadingInitial = false;

  @override
  ProviderCatalogState build(int providerId, String mediaType) {
    ref.keepAlive();
    _providerId = providerId;
    _mediaType = mediaType;
    Future.microtask(loadInitial);
    return const ProviderCatalogState();
  }

  Future<void> loadInitial() async {
    if (_isLoadingInitial || state.isLoadingMore) return;

    _isLoadingInitial = true;
    state = const ProviderCatalogState(loadStatus: Status.loading());
    try {
      final items = await ref
          .read(tmdbRepositoryProvider)
          .discoverByProvider(
            providerId: _providerId,
            mediaType: _mediaType,
            page: 1,
          );
      state = ProviderCatalogState(
        items: _deduplicateById(items),
        page: 1,
        canLoadMore: items.isNotEmpty,
        loadStatus: const Status.success(),
      );
    } catch (error) {
      state = ProviderCatalogState(
        loadStatus: Status.failure(error.toString()),
      );
    } finally {
      _isLoadingInitial = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingInitial ||
        state.isLoadingMore ||
        state.page == 0 ||
        !state.canLoadMore ||
        state.loadMoreError.isNotEmpty) {
      return;
    }

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final items = await ref
          .read(tmdbRepositoryProvider)
          .discoverByProvider(
            providerId: _providerId,
            mediaType: _mediaType,
            page: nextPage,
          );
      state = state.copyWith(
        items: _deduplicateById([...state.items, ...items]),
        page: nextPage,
        canLoadMore: items.isNotEmpty,
        isLoadingMore: false,
        loadMoreError: '',
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreError: error.toString(),
      );
    }
  }

  Future<void> retryLoadMore() async {
    if (state.isLoadingMore || state.loadMoreError.isEmpty) return;

    state = state.copyWith(loadMoreError: '');
    await loadMore();
  }
}

List<ContentItem> _deduplicateById(Iterable<ContentItem> items) {
  final ids = <String>{};
  return [
    for (final item in items)
      if (ids.add(item.id)) item,
  ];
}

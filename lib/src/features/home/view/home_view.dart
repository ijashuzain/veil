import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/alerts/view_model/alerts_view_model.dart';
import 'package:veil/src/features/auth/utils/auth_display_name.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/auth/view_model/premium_view_model/premium_view_model.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/detail/widgets/detail_review_sheet.dart';
import 'package:veil/src/features/detail/widgets/detail_social_action_sheet.dart';
import 'package:veil/src/features/detail/widgets/detail_suggestion_sheet.dart';
import 'package:veil/src/features/embeded_player/utils/playback_launcher.dart';
import 'package:veil/src/features/home/view_model/home_view_model/home_view_model.dart';
import 'package:veil/src/features/home/widgets/continue_watching_section.dart';
import 'package:veil/src/features/home/widgets/curated_collection_section.dart';
import 'package:veil/src/features/home/widgets/home_cinematic_hero.dart';
import 'package:veil/src/features/home/widgets/watch_provider_section.dart';
import 'package:veil/src/features/playback_history/models/playback_history_entry.dart';
import 'package:veil/src/features/playback_history/view_model/playback_history_view_model.dart';
import 'package:veil/src/features/social/repository/social_repository.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/shared/components/content_cards.dart';
import 'package:veil/src/shared/components/section_header.dart';
import 'package:veil/src/shared/components/skeleton.dart';
import 'package:veil/src/shared/components/veil_sheet.dart';
import 'package:veil/src/shared/components/veil_toast.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';
import 'package:veil/src/shared/models/content_item.dart';

const _categoryHeight = 52.0;
const _categoryHeroOverlap = 32.0;

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key, this.playbackLauncher = launchPlaybackRequest});

  final PlaybackRequestLauncher playbackLauncher;

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  var _editingContinueWatching = false;
  var _isLaunchingHistory = false;
  var _categoryPinned = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    ref.watch(socialLibraryViewModelProvider);
    final heroItems = state.globalTrending.take(5).toList(growable: false);
    final historyEntries = ref.watch(playbackHistoryViewModelProvider);
    final isLoading = state.loadStatus is StatusLoading;
    final selectedGenre = state.selectedGenre;
    final unreadAlerts = ref.watch(alertsViewModelProvider).unreadCount;
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight = VeilLayout.homeHeroHeight(context);
    final categoryTabs = _CategoryTabs(
      genres: state.genres,
      selected: selectedGenre,
      onChanged: (genre) =>
          ref.read(homeViewModelProvider.notifier).selectGenre(genre),
    );

    return Scaffold(
      backgroundColor: VeilColors.bg0,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [VeilColors.bg0, VeilColors.bg1, VeilColors.bg0],
            stops: [0, .46, 1],
          ),
        ),
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _HeroCategoryOverlap(
                      heroHeight: heroHeight,
                      hero: heroItems.isEmpty
                          ? const _HeroSkeleton()
                          : HomeCinematicHero(
                              items: heroItems,
                              height: heroHeight,
                              unreadAlerts: unreadAlerts,
                              onSearch: () => const SearchRoute().push(context),
                              onAlerts: () => const AlertsRoute().push(context),
                              onView: (featured) => DetailRoute(
                                id: featured.id,
                                $extra: featured,
                              ).push(context),
                              onQuickAdd: _openHeroSocialActions,
                            ),
                      categoryTabs: _categoryPinned ? null : categoryTabs,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 22)),
                  if (selectedGenre != null) ...[
                    SliverToBoxAdapter(
                      child: _SelectedGenreSeeAll(
                        title: selectedGenre.name,
                        genreId: selectedGenre.id,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    if (state.genreResults.isEmpty &&
                        state.genreStatus is StatusLoading)
                      const _GenreListSkeleton()
                    else if (state.genreResults.isEmpty)
                      SliverToBoxAdapter(
                        child: _GenreEmptyState(
                          message: state.genreStatus.errorMessage.isEmpty
                              ? 'No titles found here yet.'
                              : state.genreStatus.errorMessage,
                          onRetry: () => ref
                              .read(homeViewModelProvider.notifier)
                              .selectGenre(selectedGenre),
                        ),
                      )
                    else
                      _GenreResultList(items: state.genreResults),
                    SliverToBoxAdapter(
                      child: _GenrePaginationFooter(
                        loading: state.genreLoadingMore,
                        canLoadMore: state.genreCanLoadMore,
                        onLoadMore: () => ref
                            .read(homeViewModelProvider.notifier)
                            .loadMoreSelectedGenre(),
                      ),
                    ),
                  ] else ...[
                    if (historyEntries.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: ContinueWatchingSection(
                          entries: historyEntries,
                          editing: _editingContinueWatching,
                          onPlay: _playHistoryEntry,
                          onRemove: _removeHistoryEntry,
                          onToggleEditing: () => setState(
                            () => _editingContinueWatching =
                                !_editingContinueWatching,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    ],
                    const SliverToBoxAdapter(child: WatchProviderSection()),
                    SliverToBoxAdapter(
                      child: _LazyPosterRail(
                        title: 'Global trending',
                        section: 'trending',
                        items: state.globalTrending,
                        loading: isLoading,
                        ranked: true,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverToBoxAdapter(
                      child: _LazyPosterRail(
                        title: 'New this week',
                        section: 'upcoming',
                        items: state.newThisWeek,
                        loading: isLoading,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    const SliverToBoxAdapter(child: CuratedCollectionSection()),
                    SliverToBoxAdapter(
                      child: _LazyPosterRail(
                        title: 'Popular movies',
                        section: 'popular_movies',
                        items: state.popularMovies,
                        loading: isLoading,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverToBoxAdapter(
                      child: _LazyPosterRail(
                        title: 'Top rated movies',
                        section: 'top_rated_movies',
                        items: state.topRatedMovies,
                        loading: isLoading,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverToBoxAdapter(
                      child: _LazyPosterRail(
                        title: 'Top rated TV',
                        section: 'top_rated_tv',
                        items: state.topRatedTv,
                        loading: isLoading,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),
                    SliverToBoxAdapter(
                      child: _LazyPosterRail(
                        title: 'Airing today',
                        section: 'airing_today',
                        items: state.airingToday,
                        loading: isLoading,
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
            if (_categoryPinned)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _PinnedCategoryBar(
                  topInset: topInset,
                  child: categoryTabs,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openHeroSocialActions(ContentItem item) {
    final socialState = ref.read(socialLibraryViewModelProvider);
    final mediaType = _socialMediaType(item);
    final userEntry = socialState.entries
        .where(
          (entry) =>
              entry.tmdbId == item.remoteId && entry.mediaType == mediaType,
        )
        .firstOrNull;
    final isWatched = userEntry?.watchedOn != null;
    final isFavorite = socialState.entries.any(
      (entry) =>
          entry.isFavorite &&
          entry.tmdbId == item.remoteId &&
          entry.mediaType == mediaType,
    );
    final isInWatchlist = socialState.entries.any(
      (entry) =>
          entry.inWatchlist &&
          entry.tmdbId == item.remoteId &&
          entry.mediaType == mediaType,
    );

    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final social = ref.read(socialLibraryViewModelProvider.notifier);
        return DetailSocialActionSheet(
          item: item,
          isWatched: isWatched,
          isFavorite: isFavorite,
          isInWatchlist: isInWatchlist,
          rating: userEntry?.rating ?? 0,
          onSetWatched: ({required watched, required rating}) async {
            await social.setWatched(item, watched: watched, rating: rating);
            if (!mounted) return;
            showVeilToast(
              context,
              watched ? 'Marked watched' : 'Removed from watched',
            );
          },
          onToggleFavorite: () => social.toggleFavorite(item),
          onSetWatchlist: ({required inWatchlist}) {
            return social.setWatchlist(item, inWatchlist: inWatchlist);
          },
          onRate: ({required rating}) async {
            await social.rate(item, rating: rating);
            if (!mounted) return;
            showVeilToast(context, 'Rating saved');
          },
          onOpenReview: ({required rating}) {
            Navigator.of(sheetContext).pop();
            _openHeroReviewSheet(item, initialRating: rating);
          },
          onOpenSuggest: () {
            Navigator.of(sheetContext).pop();
            _openHeroSuggestionSheet(item);
          },
        );
      },
    );
  }

  void _openHeroReviewSheet(ContentItem item, {double initialRating = 0}) {
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DetailReviewSheet(
          item: item,
          initialRating: initialRating,
          initialWatchTag: 'first-time',
          onSave: ({required rating, required review, required tags}) async {
            await ref
                .read(socialLibraryViewModelProvider.notifier)
                .rateReview(item, rating: rating, review: review, tags: tags);
            if (!mounted) return;
            showVeilToast(context, 'Review saved');
          },
        );
      },
    );
  }

  void _openHeroSuggestionSheet(ContentItem item) {
    showVeilBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DetailSuggestionSheet(
          item: item,
          currentUserId: ref.read(socialRepositoryProvider).currentUserId,
          loadFriends: () async {
            final repository = ref.read(socialRepositoryProvider);
            return repository.friendProfiles(repository.currentUserId);
          },
          onSuggest: (recipientIds) async {
            await ref
                .read(socialRepositoryProvider)
                .suggestMovie(
                  item,
                  recipientIds: recipientIds,
                  senderDisplayName: authDisplayName(
                    ref.read(authViewModelProvider).user,
                  ),
                );
            if (!mounted) return;
            showVeilToast(context, 'Suggestion sent to friends');
          },
        );
      },
    );
  }

  Future<void> _playHistoryEntry(PlaybackHistoryEntry entry) async {
    if (_isLaunchingHistory) return;
    _isLaunchingHistory = true;
    try {
      final isPremium = await ref.read(currentUserIsPremiumProvider.future);
      if (!mounted) return;
      if (!isPremium) {
        showVeilToast(
          context,
          'Premium access is required to continue watching.',
        );
        return;
      }

      final request = entry.toRequest();
      final opened = await widget.playbackLauncher(context, request);
      if (!opened) {
        if (mounted) {
          showVeilToast(context, 'Player is not available right now.');
        }
        return;
      }

      if (!mounted) return;
      try {
        await ref
            .read(playbackHistoryViewModelProvider.notifier)
            .record(request);
      } catch (error) {
        debugPrint('Cannot update playback history: $error');
        if (mounted) {
          showVeilToast(context, 'Could not update Continue Watching.');
        }
      }
    } catch (error) {
      debugPrint('Cannot relaunch ${entry.entryKey}: $error');
      if (mounted) {
        showVeilToast(context, 'Player is not available right now.');
      }
    } finally {
      _isLaunchingHistory = false;
    }
  }

  Future<void> _removeHistoryEntry(String entryKey) async {
    await ref.read(playbackHistoryViewModelProvider.notifier).remove(entryKey);
    if (!mounted) return;
    if (ref.read(playbackHistoryViewModelProvider).isNotEmpty) {
      return;
    }
    setState(() => _editingContinueWatching = false);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final shouldPin =
        notification.metrics.pixels >=
        VeilLayout.homeHeroHeight(context) -
            _categoryHeroOverlap -
            MediaQuery.paddingOf(context).top;
    if (shouldPin != _categoryPinned) {
      setState(() => _categoryPinned = shouldPin);
    }

    if (notification.metrics.extentAfter > 520) {
      return false;
    }

    final state = ref.read(homeViewModelProvider);
    if (state.selectedGenre == null ||
        state.genreStatus is StatusLoading ||
        state.genreLoadingMore ||
        !state.genreCanLoadMore) {
      return false;
    }

    ref.read(homeViewModelProvider.notifier).loadMoreSelectedGenre();
    return false;
  }
}

String _socialMediaType(ContentItem item) {
  if (item.mediaType == 'tv') return 'tv';
  if (item.type.toLowerCase().contains('tv')) return 'tv';
  return 'movie';
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      key: const ValueKey('home-hero-skeleton'),
      width: double.infinity,
      height: VeilLayout.homeHeroHeight(context),
      radius: 0,
    );
  }
}

class _HeroCategoryOverlap extends StatelessWidget {
  const _HeroCategoryOverlap({
    required this.heroHeight,
    required this.hero,
    required this.categoryTabs,
  });

  final double heroHeight;
  final Widget hero;
  final Widget? categoryTabs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('home-hero-category-overlap'),
      height: heroHeight + _categoryHeight - _categoryHeroOverlap,
      child: Stack(
        children: [
          hero,
          if (categoryTabs case final categoryTabs?)
            Positioned(
              top: heroHeight - _categoryHeroOverlap,
              left: 0,
              right: 0,
              height: _categoryHeight,
              child: categoryTabs,
            ),
        ],
      ),
    );
  }
}

class _PinnedCategoryBar extends StatelessWidget {
  const _PinnedCategoryBar({required this.topInset, required this.child});

  final double topInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('home-pinned-category-bar'),
      height: topInset + _categoryHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: VeilColors.panel,
          border: Border(bottom: BorderSide(color: VeilColors.hairline)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: child,
        ),
      ),
    );
  }
}

class _SelectedGenreSeeAll extends StatelessWidget {
  const _SelectedGenreSeeAll({required this.title, required this.genreId});

  final String title;
  final int genreId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => SeeAllRoute(
            section: 'popular_movies',
            genreId: genreId,
            title: title,
          ).push(context),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('See all'),
          style: TextButton.styleFrom(
            foregroundColor: VeilColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreResultList extends StatelessWidget {
  const _GenreResultList({required this.items});

  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      sliver: SliverGrid.builder(
        key: const ValueKey('home-genre-grid'),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: VeilLayout.posterGridColumns(context),
          mainAxisSpacing: 20,
          crossAxisSpacing: 12,
          childAspectRatio: .49,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return PosterCard(
            key: ValueKey('genre-result-${item.id}'),
            item: item,
            width: double.infinity,
            height: 160,
            onTap: () => DetailRoute(id: item.id, $extra: item).push(context),
          );
        },
      ),
    );
  }
}

class _GenreListSkeleton extends StatelessWidget {
  const _GenreListSkeleton();

  @override
  Widget build(BuildContext context) {
    final columns = VeilLayout.posterGridColumns(context);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      sliver: SliverGrid.builder(
        key: const ValueKey('home-genre-loading-grid'),
        itemCount: columns * 2,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 20,
          crossAxisSpacing: 12,
          childAspectRatio: .49,
        ),
        itemBuilder: (_, index) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(
              key: ValueKey('home-genre-loading-$index'),
              height: 160,
              radius: 14,
            ),
            const SizedBox(height: 10),
            const SkeletonLine(height: 12),
            const SizedBox(height: 7),
            const SkeletonLine(height: 10),
          ],
        ),
      ),
    );
  }
}

class _GenreEmptyState extends StatelessWidget {
  const _GenreEmptyState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        VeilLayout.pageGutter(context),
        22,
        VeilLayout.pageGutter(context),
        8,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.movie_filter_outlined,
            color: VeilColors.text4,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: VeilColors.text3, fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _GenrePaginationFooter extends StatelessWidget {
  const _GenrePaginationFooter({
    required this.loading,
    required this.canLoadMore,
    required this.onLoadMore,
  });

  final bool loading;
  final bool canLoadMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          VeilLayout.pageGutter(context),
          8,
          VeilLayout.pageGutter(context),
          12,
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: VeilColors.red,
            ),
          ),
        ),
      );
    }

    if (!canLoadMore) return const SizedBox(height: 12);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        VeilLayout.pageGutter(context),
        4,
        VeilLayout.pageGutter(context),
        14,
      ),
      child: Center(
        child: TextButton(
          onPressed: onLoadMore,
          child: const Text('Load more'),
        ),
      ),
    );
  }
}

class _LazyPosterRail extends StatelessWidget {
  const _LazyPosterRail({
    required this.title,
    required this.section,
    required this.items,
    required this.loading,
    this.ranked = false,
  });

  final String title;
  final String section;
  final List<ContentItem> items;
  final bool loading;
  final bool ranked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          trailing: 'See all',
          onTap: () =>
              SeeAllRoute(section: section, title: title).push(context),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty && loading)
          const _SkeletonRail(width: 124, height: 206)
        else
          SizedBox(
            height: ranked ? 192 : 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: VeilLayout.pageGutter(context),
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final card = PosterCard(
                  item: item,
                  onTap: () =>
                      DetailRoute(id: item.id, $extra: item).push(context),
                  showMeta: !ranked,
                );
                if (!ranked) return card;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -8,
                      bottom: 26,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.transparent,
                          fontSize: 76,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: VeilColors.gold.withValues(alpha: .92),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    card,
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SkeletonRail extends StatelessWidget {
  const _SkeletonRail({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: VeilLayout.pageGutter(context),
        ),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => SkeletonBox(width: width, height: height),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.genres,
    required this.selected,
    required this.onChanged,
  });

  final List<TmdbGenre> genres;
  final TmdbGenre? selected;
  final ValueChanged<TmdbGenre?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [const TmdbGenre(id: -1, name: 'All'), ...genres];
    return SingleChildScrollView(
      key: const ValueKey('home-category-tabs'),
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      child: Row(
        children: [
          for (final genre in items)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(genre.id == -1 ? null : genre),
                child: _GenreTabLabel(
                  label: genre.name,
                  selected: genre.id == -1
                      ? selected == null
                      : selected?.id == genre.id,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GenreTabLabel extends StatelessWidget {
  const _GenreTabLabel({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : VeilColors.panelRaised,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.white : VeilColors.hairline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : VeilColors.text2,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

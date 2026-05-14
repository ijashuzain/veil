import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/alerts/view_model/alerts_view_model.dart';
import 'package:veil/src/features/auth/utils/auth_display_name.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/home/view_model/home_view_model/home_view_model.dart';
import 'package:veil/src/shared/components/content_cards.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/components/section_header.dart';
import 'package:veil/src/shared/components/skeleton.dart';
import 'package:veil/src/shared/models/content_item.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final featured = state.featured;
    final isLoading = state.loadStatus is StatusLoading;
    final selectedGenre = state.selectedGenre;
    final unreadAlerts = ref.watch(alertsViewModelProvider).unreadCount;
    final topInset = MediaQuery.paddingOf(context).top;
    final gutter = VeilLayout.pageGutter(context);
    final heroHeight = VeilLayout.homeHeroHeight(context);
    final name = authDisplayName(
      ref.watch(authViewModelProvider).user,
      fallback: 'there',
    );

    return Scaffold(
      backgroundColor: VeilColors.bg1,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, topInset + 14, gutter, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Gap(8),
                          const Text(
                            'Tonight on Veil',
                            style: TextStyle(
                              color: VeilColors.text3,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .7,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hello, $name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ActionCircle(
                      icon: Icons.search_rounded,
                      onTap: () => const SearchRoute().push(context),
                    ),
                    const SizedBox(width: 8),
                    ActionCircle(
                      icon: Icons.notifications_none_rounded,
                      badge: unreadAlerts > 0,
                      onTap: () => const AlertsRoute().push(context),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 0),
                child: featured == null
                    ? const _HeroSkeleton()
                    : GestureDetector(
                        onTap: () => DetailRoute(
                          id: featured.id,
                          $extra: featured,
                        ).push(context),
                        child: BackdropArt(
                          item: featured,
                          width: double.infinity,
                          height: heroHeight,
                          radius: 22,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeroBadge(),
                                const Spacer(),
                                Text(
                                  featured.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: .98,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  featured.subtitle.toUpperCase(),
                                  style: const TextStyle(
                                    color: VeilColors.text2,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3.8,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 5,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFBBF24),
                                      size: 14,
                                    ),
                                    Text(
                                      featured.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: VeilColors.text2,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      '·',
                                      style: TextStyle(color: VeilColors.text4),
                                    ),
                                    Text(
                                      '${featured.year}',
                                      style: const TextStyle(
                                        color: VeilColors.text2,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      '·',
                                      style: TextStyle(color: VeilColors.text4),
                                    ),
                                    Text(
                                      featured.genre.split('/').first.trim(),
                                      style: const TextStyle(
                                        color: VeilColors.text2,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const _HeroDots(),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryHeaderDelegate(
                topInset: topInset,
                child: _CategoryTabs(
                  genres: state.genres,
                  selected: selectedGenre,
                  onChanged: (genre) => ref
                      .read(homeViewModelProvider.notifier)
                      .selectGenre(genre),
                ),
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
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical ||
        notification.metrics.extentAfter > 520) {
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

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.white, size: 6),
            SizedBox(width: 6),
            Text(
              'Featured',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroDots extends StatelessWidget {
  const _HeroDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index == 0 ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: index == 0 ? Colors.white : Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          if (index != 2) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: double.infinity,
      height: VeilLayout.homeHeroHeight(context),
      radius: 22,
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
            foregroundColor: Colors.white,
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
    final breakpoint = VeilBreakpoint.of(context);
    final gutter = VeilLayout.pageGutter(context);
    if (breakpoint.isDesktop) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        sliver: SliverGrid.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 3.5,
          ),
          itemBuilder: (context, index) => _GenreResultTile(item: items[index]),
        ),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _GenreResultTile(item: item),
          );
        }, childCount: items.length),
      ),
    );
  }
}

class _GenreResultTile extends StatelessWidget {
  const _GenreResultTile({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final year = item.year > 0 ? '${item.year}' : item.type;
    final genre = item.genre.split('/').first.trim();
    return GestureDetector(
      key: ValueKey('genre-result-${item.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => DetailRoute(id: item.id, $extra: item).push(context),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: VeilColors.hairline)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterArt(
                item: item,
                width: 82,
                height: 124,
                radius: 10,
                showTitle: false,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$year / $genre',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VeilColors.text3,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBF24),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: VeilColors.text2,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VeilColors.text3,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreListSkeleton extends StatelessWidget {
  const _GenreListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SkeletonBox(width: 82, height: 124, radius: 10),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: double.infinity, height: 18),
                      SizedBox(height: 12),
                      SkeletonBox(width: 150, height: 12),
                      SizedBox(height: 16),
                      SkeletonBox(width: 72, height: 12),
                      SizedBox(height: 18),
                      SkeletonBox(width: double.infinity, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        }, childCount: 4),
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
            height: ranked ? 188 : 226,
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
                              color: VeilColors.red.withValues(alpha: .90),
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
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      child: Row(
        children: [
          for (final genre in items)
            Padding(
              padding: const EdgeInsets.only(right: 22),
              child: InkWell(
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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : VeilColors.text3,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: selected ? 22 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: VeilColors.red,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CategoryHeaderDelegate({required this.child, required this.topInset});

  final Widget child;
  final double topInset;

  @override
  double get minExtent => topInset + 52;

  @override
  double get maxExtent => topInset + 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.bg1.withValues(alpha: .97),
        border: Border(
          bottom: BorderSide(
            color: overlapsContent ? VeilColors.hairline : Colors.transparent,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: Align(alignment: Alignment.bottomLeft, child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.topInset != topInset;
  }
}

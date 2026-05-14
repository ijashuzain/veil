import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/catalog/repository/tmdb_repository.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/shared/components/content_cards.dart';
import 'package:veil/src/shared/components/skeleton.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';
import 'package:veil/src/shared/models/content_item.dart';

class SeeAllView extends ConsumerStatefulWidget {
  const SeeAllView({
    super.key,
    required this.section,
    this.genreId,
    this.title,
  });

  final String section;
  final int? genreId;
  final String? title;

  @override
  ConsumerState<SeeAllView> createState() => _SeeAllViewState();
}

class _SeeAllViewState extends ConsumerState<SeeAllView> {
  final _items = <ContentItem>[];
  var _genres = <TmdbGenre>[];
  var _page = 1;
  var _loading = false;
  var _canLoadMore = true;
  var _minRating = 0.0;
  int? _genreId;
  String? _socialGenre;
  var _visibleSocialCount = 18;

  bool get _isSocialSection {
    return {
      'diary',
      'watchlist',
      'favorites',
      'my_reviews',
    }.contains(widget.section);
  }

  @override
  void initState() {
    super.initState();
    _genreId = widget.genreId;
    if (!_isSocialSection) {
      Future.microtask(() {
        _loadGenres();
        _loadPage(reset: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialLibraryViewModelProvider);
    final socialEntries = _filteredSocialEntries(social);
    final gutter = VeilLayout.pageGutter(context);

    return Scaffold(
      backgroundColor: VeilColors.bg1,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                (gutter - 8).clamp(12, gutter).toDouble(),
                56,
                gutter,
                12,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Filters(
              genres: _isSocialSection ? _socialGenres(socialEntries) : _genres,
              selectedGenreId: _genreId,
              selectedSocialGenre: _socialGenre,
              minRating: _minRating,
              isSocial: _isSocialSection,
              onGenre: (value) {
                setState(() {
                  if (_isSocialSection) {
                    _socialGenre = value as String?;
                  } else {
                    _genreId = value as int?;
                  }
                  _visibleSocialCount = 18;
                });
                if (!_isSocialSection) _loadPage(reset: true);
              },
              onRating: (value) {
                setState(() {
                  _minRating = value;
                  _visibleSocialCount = 18;
                });
                if (!_isSocialSection) _loadPage(reset: true);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          if (_isSocialSection)
            _SocialGrid(
              entries: socialEntries.take(_visibleSocialCount).toList(),
            )
          else if (_items.isEmpty && _loading)
            const SliverToBoxAdapter(child: _GridSkeleton())
          else
            _ContentGrid(items: _items),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 110),
              child: _isSocialSection
                  ? _visibleSocialCount < socialEntries.length
                        ? _LoadMoreButton(
                            loading: false,
                            onTap: () =>
                                setState(() => _visibleSocialCount += 18),
                          )
                        : const SizedBox.shrink()
                  : _canLoadMore
                  ? _LoadMoreButton(loading: _loading, onTap: () => _loadPage())
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    return widget.title ??
        switch (widget.section) {
          'trending' => 'Global trending',
          'upcoming' => 'New this week',
          'popular_movies' => 'Popular movies',
          'top_rated_movies' => 'Top rated movies',
          'top_rated_tv' => 'Top rated TV',
          'airing_today' => 'Airing today',
          'watchlist' => 'Watchlist',
          'favorites' => 'Favorites',
          'my_reviews' => 'My reviews',
          _ => 'See all',
        };
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await ref.read(tmdbRepositoryProvider).genresDetailed();
      if (!mounted) return;
      setState(() => _genres = genres);
    } catch (_) {}
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _canLoadMore = true;
        _items.clear();
      }
    });
    try {
      final pageItems = await ref
          .read(tmdbRepositoryProvider)
          .sectionPage(
            widget.section,
            page: _page,
            genreId: _genreId,
            minRating: _minRating,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(pageItems);
        _page += 1;
        _canLoadMore = pageItems.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _canLoadMore = false;
        _loading = false;
      });
    }
  }

  List<SocialEntry> _filteredSocialEntries(SocialLibraryViewState state) {
    final entries = switch (widget.section) {
      'watchlist' => state.watchlist,
      'favorites' => state.favorites,
      'my_reviews' => state.reviews,
      _ => state.diary,
    };
    return entries.where((entry) {
      final genreMatch =
          _socialGenre == null ||
          entry.genre.toLowerCase().contains(_socialGenre!.toLowerCase());
      final ratingMatch = _minRating == 0 || entry.rating >= _minRating;
      return genreMatch && ratingMatch;
    }).toList();
  }

  List<String> _socialGenres(List<SocialEntry> entries) {
    return entries
        .expand((entry) => entry.genre.split('/'))
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .toSet()
        .toList();
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.genres,
    required this.selectedGenreId,
    required this.selectedSocialGenre,
    required this.minRating,
    required this.isSocial,
    required this.onGenre,
    required this.onRating,
  });

  final List<Object> genres;
  final int? selectedGenreId;
  final String? selectedSocialGenre;
  final double minRating;
  final bool isSocial;
  final ValueChanged<Object?> onGenre;
  final ValueChanged<double> onRating;

  @override
  Widget build(BuildContext context) {
    final gutter = VeilLayout.pageGutter(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Row(
            children: [
              _ChipButton(
                label: 'All',
                selected: isSocial
                    ? selectedSocialGenre == null
                    : selectedGenreId == null,
                onTap: () => onGenre(null),
              ),
              for (final genre in genres)
                _ChipButton(
                  label: genre is TmdbGenre ? genre.name : genre.toString(),
                  selected: genre is TmdbGenre
                      ? selectedGenreId == genre.id
                      : selectedSocialGenre == genre.toString(),
                  onTap: () =>
                      onGenre(genre is TmdbGenre ? genre.id : genre.toString()),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Row(
            children: [
              for (final rating in const [0.0, 2.0, 3.0, 4.0, 4.5])
                _ChipButton(
                  label: rating == 0
                      ? 'Any rating'
                      : '${rating.toStringAsFixed(1)}+',
                  selected: minRating == rating,
                  onTap: () => onRating(rating),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text(label),
        selectedColor: VeilColors.red,
        backgroundColor: VeilColors.bg2,
        side: const BorderSide(color: VeilColors.hairline),
        labelStyle: TextStyle(
          color: selected ? Colors.white : VeilColors.text2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ContentGrid extends StatelessWidget {
  const _ContentGrid({required this.items});

  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SliverToBoxAdapter(child: _EmptyState());
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      sliver: SliverGrid.builder(
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: VeilLayout.posterGridColumns(context),
          mainAxisSpacing: 24,
          crossAxisSpacing: VeilBreakpoint.of(context).isMobile ? 12 : 16,
          childAspectRatio: VeilBreakpoint.of(context).isDesktop ? .52 : .49,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return PosterCard(
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

class _SocialGrid extends StatelessWidget {
  const _SocialGrid({required this.entries});

  final List<SocialEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SliverToBoxAdapter(child: _EmptyState());
    return _ContentGrid(
      items: entries.map((entry) => entry.toContentItem()).toList(),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: VeilLayout.posterGridColumns(context),
          mainAxisSpacing: 18,
          crossAxisSpacing: 12,
          childAspectRatio: .58,
        ),
        itemCount: 9,
        itemBuilder: (_, _) => const SkeletonBox(height: 180),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: VeilColors.hairlineStrong),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VeilColors.red,
                ),
              )
            : const Text('Load more'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'No matching titles yet.',
        style: TextStyle(color: VeilColors.text3),
      ),
    );
  }
}

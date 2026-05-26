import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/features/social/widgets/diary_filter_sheet.dart';
import 'package:veil/src/features/social/widgets/diary_poster_grid.dart';
import 'package:veil/src/shared/components/veil_filter_chips.dart';
import 'package:veil/src/shared/components/veil_segmented_tabs.dart';
import 'package:veil/src/shared/components/veil_sheet.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class DiaryView extends ConsumerStatefulWidget {
  const DiaryView({super.key});

  @override
  ConsumerState<DiaryView> createState() => _DiaryViewState();
}

class _DiaryViewState extends ConsumerState<DiaryView> {
  var _selectedTab = _DiaryTab.watched;
  var _filters = const DiaryFilterState();
  var _tabDragDistance = 0.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialLibraryViewModelProvider);
    final entries = _filteredEntries(_entriesForTab(state));
    final baseEntries = _entriesForTab(state);
    final activeFilters = _activeFilterLabels();
    final gutter = VeilLayout.pageGutter(context);

    return Scaffold(
      backgroundColor: VeilColors.bg0,
      body: RefreshIndicator(
        color: VeilColors.red,
        backgroundColor: VeilColors.bg2,
        onRefresh: () =>
            ref.read(socialLibraryViewModelProvider.notifier).load(),
        child: GestureDetector(
          key: const ValueKey('diary-tab-swipe-area'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _tabDragDistance = 0,
          onHorizontalDragUpdate: (details) {
            _tabDragDistance += details.delta.dx;
          },
          onHorizontalDragEnd: (_) {
            if (_tabDragDistance < -80) {
              _selectAdjacentTab(1, state);
            } else if (_tabDragDistance > 80) {
              _selectAdjacentTab(-1, state);
            }
            _tabDragDistance = 0;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    VeilLayout.pageTopPadding(context),
                    gutter,
                    0,
                  ),
                  child: const Text(
                    'Diary',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 0),
                  child: _StatsStrip(
                    watched: state.diary.length,
                    watchlist: state.watchlist.length,
                    favorites: state.favorites.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 0),
                  child: VeilSegmentedTabs<_DiaryTab>(
                    selected: _selectedTab,
                    segments: [
                      for (final tab in _DiaryTab.values)
                        VeilSegment(value: tab, label: tab.label),
                    ],
                    onChanged: (tab) => _selectTab(tab, state),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 0),
                  child: _DiaryToolbar(
                    count: entries.length,
                    tab: _selectedTab,
                    sort: _filters.sortMode,
                    activeFilterCount: _filters.activeCount,
                    onOpenFilter: () => _openFilters(state),
                  ),
                ),
              ),
              if (activeFilters.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 0),
                    child: _ActiveFilterStrip(
                      labels: activeFilters,
                      onClear: () =>
                          setState(() => _filters = const DiaryFilterState()),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (state.entries.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  sliver: const SliverToBoxAdapter(child: _StarterPanel()),
                )
              else if (baseEntries.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyText(_emptyTextForTab(_selectedTab)),
                  ),
                )
              else if (entries.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyText(_emptyTextForTab(_selectedTab)),
                  ),
                )
              else
                DiaryPosterGrid(
                  entries: entries,
                  footer: switch (_selectedTab) {
                    _DiaryTab.watched => DiaryGridFooter.stars,
                    _DiaryTab.watchlist => DiaryGridFooter.year,
                    _DiaryTab.favorites => DiaryGridFooter.favorite,
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 118)),
            ],
          ),
        ),
      ),
    );
  }

  List<SocialEntry> _entriesForTab(SocialLibraryViewState state) {
    return switch (_selectedTab) {
      _DiaryTab.watched => state.diary,
      _DiaryTab.watchlist => state.watchlist,
      _DiaryTab.favorites => state.favorites,
    };
  }

  List<SocialEntry> _filteredEntries(List<SocialEntry> entries) {
    final filtered = entries.where((entry) {
      final genreMatch =
          _filters.genre == null ||
          entry.genre.toLowerCase().contains(_filters.genre!.toLowerCase());
      final ratingMatch =
          _filters.minimumRating == 0 || entry.rating >= _filters.minimumRating;
      final yearMatch = _filters.yearFilter.matches(entry.year);
      return genreMatch && ratingMatch && yearMatch;
    }).toList();

    return _sortEntries(filtered, _filters.sortMode);
  }

  List<String> _genresForTab(SocialLibraryViewState state) {
    return _entriesForTab(state)
        .expand((entry) => entry.genre.split('/'))
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .toSet()
        .toList();
  }

  List<SocialEntry> _sortEntries(
    List<SocialEntry> entries,
    DiarySortMode sortMode,
  ) {
    final sorted = [...entries];
    switch (sortMode) {
      case DiarySortMode.recent:
        sorted.sort((a, b) => _entryDate(b).compareTo(_entryDate(a)));
      case DiarySortMode.highestRated:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case DiarySortMode.lowestRated:
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
      case DiarySortMode.az:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case DiarySortMode.year:
        sorted.sort((a, b) => b.year.compareTo(a.year));
    }
    return sorted;
  }

  DateTime _entryDate(SocialEntry entry) {
    return entry.watchedOn ?? entry.updatedAt;
  }

  void _selectTab(_DiaryTab tab, SocialLibraryViewState state) {
    final genres = _genresForTabForSelection(tab, state);
    setState(() {
      _selectedTab = tab;
      if (_filters.genre != null && !genres.contains(_filters.genre)) {
        _filters = _filters.copyWith(clearGenre: true);
      }
    });
  }

  void _selectAdjacentTab(int delta, SocialLibraryViewState state) {
    final tabs = _DiaryTab.values;
    final current = tabs.indexOf(_selectedTab);
    final next = (current + delta).clamp(0, tabs.length - 1);
    if (next == current) return;
    _selectTab(tabs[next], state);
  }

  List<String> _genresForTabForSelection(
    _DiaryTab tab,
    SocialLibraryViewState state,
  ) {
    final entries = switch (tab) {
      _DiaryTab.watched => state.diary,
      _DiaryTab.watchlist => state.watchlist,
      _DiaryTab.favorites => state.favorites,
    };
    return entries
        .expand((entry) => entry.genre.split('/'))
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> _openFilters(SocialLibraryViewState state) async {
    final entries = _entriesForTab(state);
    final result = await showVeilBottomSheet<DiaryFilterState>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DiaryFilterSheet(
        initial: _filters,
        genres: _genresForTab(state),
        resultCountFor: (filters) => _sortEntries(
          entries.where((entry) {
            final genreMatch =
                filters.genre == null ||
                entry.genre.toLowerCase().contains(
                  filters.genre!.toLowerCase(),
                );
            final ratingMatch =
                filters.minimumRating == 0 ||
                entry.rating >= filters.minimumRating;
            return genreMatch &&
                ratingMatch &&
                filters.yearFilter.matches(entry.year);
          }).toList(),
          filters.sortMode,
        ).length,
      ),
    );
    if (result != null) {
      setState(() => _filters = result);
    }
  }

  List<String> _activeFilterLabels() {
    return [
      if (_filters.genre != null) _filters.genre!,
      if (_filters.minimumRating > 0)
        '${_filters.minimumRating.toStringAsFixed(1)}+',
      if (_filters.yearFilter != DiaryYearFilter.any) _filters.yearFilter.label,
      if (_filters.sortMode != DiarySortMode.recent) _filters.sortMode.label,
    ];
  }
}

enum _DiaryTab {
  watched('Watched'),
  watchlist('Watchlist'),
  favorites('Favorites');

  const _DiaryTab(this.label);

  final String label;
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.watched,
    required this.watchlist,
    required this.favorites,
  });

  final int watched;
  final int watchlist;
  final int favorites;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VeilColors.panel.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VeilColors.hairlineStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatValue(value: watched, label: 'Films'),
            _StatValue(value: watchlist, label: 'Watchlist'),
            _StatValue(value: favorites, label: 'Favorites'),
          ],
        ),
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: VeilColors.text4, fontSize: 10),
        ),
      ],
    );
  }
}

class _DiaryToolbar extends StatelessWidget {
  const _DiaryToolbar({
    required this.count,
    required this.tab,
    required this.sort,
    required this.activeFilterCount,
    required this.onOpenFilter,
  });

  final int count;
  final _DiaryTab tab;
  final DiarySortMode sort;
  final int activeFilterCount;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$count',
                  style: const TextStyle(color: Colors.white),
                ),
                TextSpan(text: ' ${tab.label.toLowerCase()}'),
                TextSpan(text: ' · ${sort.label.toLowerCase()}'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: VeilColors.text3,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onOpenFilter,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: activeFilterCount > 0
                  ? VeilColors.redSoft
                  : VeilColors.panel,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: activeFilterCount > 0
                    ? VeilColors.red.withValues(alpha: .46)
                    : VeilColors.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 15,
                  color: activeFilterCount > 0
                      ? VeilColors.red
                      : VeilColors.text2,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filter',
                  style: TextStyle(
                    color: activeFilterCount > 0
                        ? VeilColors.red
                        : VeilColors.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (activeFilterCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: VeilColors.red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveFilterStrip extends StatelessWidget {
  const _ActiveFilterStrip({required this.labels, required this.onClear});

  final List<String> labels;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final label in labels) ...[
            VeilChoiceChip(label: label, selected: true, compact: true),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: VeilColors.text3,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _StarterPanel extends StatelessWidget {
  const _StarterPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VeilColors.hairlineStrong),
        color: VeilColors.panel,
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start your film diary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Rate, review, save watchlist picks, and favorite the films you want close.',
                    style: TextStyle(
                      color: VeilColors.text3,
                      height: 1.35,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.search_rounded, color: VeilColors.text3, size: 28),
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: VeilColors.text3, height: 1.4),
    );
  }
}

String _emptyTextForTab(_DiaryTab tab) {
  return switch (tab) {
    _DiaryTab.watched => 'No watched films match these filters.',
    _DiaryTab.watchlist => 'Your watchlist picks appear here.',
    _DiaryTab.favorites => 'Favorite films appear here.',
  };
}

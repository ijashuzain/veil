import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/auth/utils/auth_display_name.dart';
import 'package:veil/src/features/auth/view_model/auth_view_model/auth_view_model.dart';
import 'package:veil/src/features/search/view_model/search_view_model/search_view_model.dart';
import 'package:veil/src/features/social/models/social_entry/social_entry.dart';
import 'package:veil/src/features/social/models/user_profile_summary.dart';
import 'package:veil/src/features/social/view_model/social_library_view_model/social_library_view_model.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/components/skeleton.dart';
import 'package:veil/src/shared/components/veil_filter_chips.dart';
import 'package:veil/src/shared/layout/adaptive_content.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';
import 'package:veil/src/shared/models/content_item.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key, this.showBack = false});

  final bool showBack;

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final _controller = TextEditingController();
  Timer? _debounce;
  var _scope = _SearchScope.all;
  final _recentSearches = <_RecentSearch>[];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchViewModelProvider);
    final social = ref.watch(socialLibraryViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final results = state.results;
    final isLoading = state.searchStatus is StatusLoading;
    final users = _matchingUsers(
      directoryUsers: state.users,
      globalReviews: social.globalReviews,
      localEntries: social.entries,
      query: state.query,
      currentUserId: auth.user?.id ?? 'local-user',
      currentDisplayName: auth.user == null ? null : authDisplayName(auth.user),
    );
    final filmResults = _filmResults(results);
    final castResults = _castResults(results);
    final visibleResults = switch (_scope) {
      _SearchScope.all => results,
      _SearchScope.users => const <ContentItem>[],
      _SearchScope.films => filmResults,
      _SearchScope.cast => castResults,
    };
    final scopeCounts = _SearchScopeCounts(
      all: users.length + results.length,
      users: users.length,
      films: filmResults.length,
      cast: castResults.length,
    );
    final showUsers =
        _scope == _SearchScope.all || _scope == _SearchScope.users;
    final showResults =
        _scope == _SearchScope.all ||
        _scope == _SearchScope.films ||
        _scope == _SearchScope.cast;
    final showGenres =
        _scope == _SearchScope.all || _scope == _SearchScope.films;

    if (_controller.text != state.query) {
      _controller.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return Scaffold(
      backgroundColor: VeilColors.bg0,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          VeilLayout.pageTopPadding(context),
          0,
          28,
        ),
        child: AdaptiveContent(
          maxWidth: VeilLayout.readableMaxWidth(context),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 20, 4),
                child: Row(
                  children: [
                    if (widget.showBack)
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                      )
                    else
                      const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (widget.showBack)
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Find films, cast + crew, members...',
                    hintStyle: const TextStyle(color: VeilColors.text3),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: VeilColors.text3,
                    ),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _clearSearch();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                    filled: true,
                    fillColor: VeilColors.panelRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        VeilTheme.controlRadius,
                      ),
                      borderSide: const BorderSide(color: VeilColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        VeilTheme.controlRadius,
                      ),
                      borderSide: const BorderSide(color: VeilColors.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        VeilTheme.controlRadius,
                      ),
                      borderSide: const BorderSide(color: VeilColors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SearchScopeChips(
                selected: _scope,
                counts: scopeCounts,
                showCounts: state.query.trim().isNotEmpty,
                onChanged: (scope) => setState(() => _scope = scope),
              ),
              if (_recentSearches.isNotEmpty) ...[
                const SizedBox(height: 20),
                _RecentSearchesSection(
                  searches: _recentSearches,
                  onTap: _selectRecentSearch,
                  onClear: () => setState(_recentSearches.clear),
                ),
              ],
              if (showUsers && users.isNotEmpty) ...[
                const SizedBox(height: 22),
                const _BlockTitle('App users'),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      for (final user in users)
                        _UserResult(
                          user: user,
                          onTap: () => _openUserResult(user),
                        ),
                    ],
                  ),
                ),
              ],
              if (showResults) ...[
                const SizedBox(height: 24),
                _BlockTitle(
                  _scope == _SearchScope.cast
                      ? 'Cast, crew or studios'
                      : 'Top results',
                ),
                const SizedBox(height: 12),
                if (visibleResults.isEmpty)
                  isLoading
                      ? const _SearchResultsSkeleton()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _emptyTextForScope(_scope, state.query),
                            style: const TextStyle(color: VeilColors.text3),
                          ),
                        )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        for (final item in visibleResults.take(8))
                          _SearchResult(
                            item: item,
                            onTap: () => _openContentResult(item),
                          ),
                      ],
                    ),
                  ),
              ],
              if (showGenres) ...[
                const SizedBox(height: 24),
                const _BlockTitle('Browse genres'),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: state.genres.isEmpty && isLoading
                      ? const _GenreSkeletonGrid()
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: VeilLayout.genreGridColumns(
                                  context,
                                ),
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.75,
                              ),
                          itemCount: state.genres.length,
                          itemBuilder: (context, index) {
                            final genre = state.genres[index];
                            final color = _genreColor(index);
                            return InkWell(
                              onTap: () => SeeAllRoute(
                                section: 'popular_movies',
                                title: genre,
                              ).push(context),
                              borderRadius: BorderRadius.circular(12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: VeilColors.hairline,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [color, VeilColors.bg0],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      genre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onQueryChanged(String value) {
    setState(() {});
    ref.read(searchViewModelProvider.notifier).setQuery(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      unawaited(_runSearch(value));
    });
  }

  Future<void> _runSearch(String value) async {
    await ref.read(searchViewModelProvider.notifier).search(value);
  }

  void _openUserResult(_SearchUser user) {
    _rememberSearch(user.displayName, scope: _SearchScope.users);
    UserProfileRoute(
      id: user.userId,
      displayName: user.displayName,
    ).push(context);
  }

  void _openContentResult(ContentItem item) {
    _rememberSearch(
      item.title,
      scope: _isCastResult(item) ? _SearchScope.cast : _SearchScope.films,
    );
    DetailRoute(id: item.id, $extra: item).push(context);
  }

  void _rememberSearch(String value, {required _SearchScope scope}) {
    final query = value.trim();
    if (query.isEmpty) return;
    setState(() {
      _recentSearches.removeWhere(
        (search) => search.query.toLowerCase() == query.toLowerCase(),
      );
      _recentSearches.insert(0, _RecentSearch(query: query, scope: scope));
      if (_recentSearches.length > 5) {
        _recentSearches.removeRange(5, _recentSearches.length);
      }
    });
  }

  void _selectRecentSearch(_RecentSearch search) {
    setState(() => _scope = search.scope);
    _controller.text = search.query;
    _controller.selection = TextSelection.collapsed(
      offset: search.query.length,
    );
    ref.read(searchViewModelProvider.notifier).setQuery(search.query);
    unawaited(_runSearch(search.query));
  }

  void _clearSearch() {
    setState(_controller.clear);
    ref.read(searchViewModelProvider.notifier).clear();
  }
}

enum _SearchScope {
  all('All'),
  users('Users'),
  films('Films'),
  cast('Cast');

  const _SearchScope(this.label);

  final String label;
}

class _RecentSearch {
  const _RecentSearch({required this.query, required this.scope});

  final String query;
  final _SearchScope scope;
}

class _SearchScopeCounts {
  const _SearchScopeCounts({
    required this.all,
    required this.users,
    required this.films,
    required this.cast,
  });

  final int all;
  final int users;
  final int films;
  final int cast;

  int forScope(_SearchScope scope) {
    return switch (scope) {
      _SearchScope.all => all,
      _SearchScope.users => users,
      _SearchScope.films => films,
      _SearchScope.cast => cast,
    };
  }
}

class _SearchScopeChips extends StatelessWidget {
  const _SearchScopeChips({
    required this.selected,
    required this.counts,
    required this.showCounts,
    required this.onChanged,
  });

  final _SearchScope selected;
  final _SearchScopeCounts counts;
  final bool showCounts;
  final ValueChanged<_SearchScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final scope in _SearchScope.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ScopeChip(
                scope: scope,
                count: showCounts ? counts.forScope(scope) : null,
                selected: selected == scope,
                onTap: () => onChanged(scope),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.scope,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final _SearchScope scope;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : VeilColors.text2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
      child: Container(
        height: VeilTheme.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? VeilColors.redSoft : VeilColors.bg2,
          borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
          border: Border.all(
            color: selected
                ? VeilColors.red.withValues(alpha: .42)
                : VeilColors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              scope.label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 7),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .12)
                      : VeilColors.panelRaised,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : VeilColors.text3,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentSearchesSection extends StatelessWidget {
  const _RecentSearchesSection({
    required this.searches,
    required this.onTap,
    required this.onClear,
  });

  final List<_RecentSearch> searches;
  final ValueChanged<_RecentSearch> onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _BlockTitleBare('Recent searches')),
              TextButton(onPressed: onClear, child: const Text('Clear recent')),
            ],
          ),
          const SizedBox(height: 8),
          for (final search in searches)
            InkWell(
              onTap: () => onTap(search),
              borderRadius: BorderRadius.circular(VeilTheme.controlRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: VeilColors.text3,
                      size: 19,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        search.query,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    VeilChoiceChip(
                      label: search.scope.label,
                      selected: false,
                      onTap: () => onTap(search),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        label,
        style: const TextStyle(
          color: VeilColors.text2,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _BlockTitleBare extends StatelessWidget {
  const _BlockTitleBare(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: VeilColors.text2,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
      ),
    );
  }
}

class _SearchUser {
  const _SearchUser({
    required this.userId,
    required this.displayName,
    required this.reviewCount,
  });

  final String userId;
  final String displayName;
  final int reviewCount;
}

List<_SearchUser> _matchingUsers({
  required List<UserProfileSummary> directoryUsers,
  required List<SocialEntry> globalReviews,
  required List<SocialEntry> localEntries,
  required String query,
  required String currentUserId,
  required String? currentDisplayName,
}) {
  final lookup = <String, ({String displayName, int reviewCount})>{};

  void include(String userId, {String? displayName, int reviews = 0}) {
    if (userId == currentUserId) return;
    final existing = lookup[userId];
    final resolvedDisplayName =
        displayName ?? existing?.displayName ?? _displayName(userId);
    if (_isHiddenSearchUser(resolvedDisplayName)) {
      lookup.remove(userId);
      return;
    }
    lookup[userId] = (
      displayName: resolvedDisplayName,
      reviewCount: (existing?.reviewCount ?? 0) + reviews,
    );
  }

  for (final review in globalReviews) {
    include(review.userId, reviews: 1);
  }
  for (final user in directoryUsers) {
    include(user.userId, displayName: user.displayName);
  }
  for (final entry in localEntries) {
    include(
      entry.userId,
      displayName: entry.userId == currentUserId ? currentDisplayName : null,
      reviews: entry.review.trim().isEmpty ? 0 : 1,
    );
  }
  final normalized = query.trim().toLowerCase();
  return lookup.entries
      .map(
        (entry) => _SearchUser(
          userId: entry.key,
          displayName: entry.value.displayName,
          reviewCount: entry.value.reviewCount,
        ),
      )
      .where(
        (user) => normalized.isEmpty
            ? false
            : user.displayName.toLowerCase().contains(normalized) ||
                  user.userId.toLowerCase().contains(normalized) ||
                  _displayName(user.userId).toLowerCase().contains(normalized),
      )
      .take(6)
      .toList();
}

bool _isHiddenSearchUser(String displayName) {
  return displayName.trim().toLowerCase().contains('siyana');
}

List<ContentItem> _filmResults(List<ContentItem> results) {
  return results.where((item) => !_isCastResult(item)).toList();
}

List<ContentItem> _castResults(List<ContentItem> results) {
  return results.where(_isCastResult).toList();
}

bool _isCastResult(ContentItem item) {
  final type = item.type.toLowerCase();
  final mediaType = item.mediaType.toLowerCase();
  return mediaType == 'person' ||
      type.contains('person') ||
      type.contains('cast') ||
      type.contains('crew') ||
      type.contains('studio');
}

String _emptyTextForScope(_SearchScope scope, String query) {
  final searching = query.trim().isNotEmpty;
  return switch (scope) {
    _SearchScope.cast =>
      searching
          ? 'No cast, crew, or studios found.'
          : 'Search TMDB for cast, crew, and studios.',
    _SearchScope.users => 'No members found.',
    _SearchScope.all || _SearchScope.films =>
      searching
          ? 'No films or shows found.'
          : 'Search TMDB for movies, shows, and people.',
  };
}

String _displayName(String userId) {
  final count = userId.length < 8 ? userId.length : 8;
  return '@${userId.substring(0, count)}';
}

class _UserResult extends StatelessWidget {
  const _UserResult({required this.user, required this.onTap});

  final _SearchUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: VeilColors.bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VeilColors.hairline),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: VeilColors.red.withValues(alpha: .18),
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${user.reviewCount} review${user.reviewCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: VeilColors.text3,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: VeilColors.text3),
          ],
        ),
      ),
    );
  }
}

Color _genreColor(int index) {
  const colors = [
    Color(0xFF7C2D12),
    Color(0xFF1E3A5F),
    Color(0xFF3A0A5E),
    Color(0xFFA8082E),
    Color(0xFF064E3B),
    Color(0xFF4338CA),
  ];
  return colors[index % colors.length];
}

class _SearchResultsSkeleton extends StatelessWidget {
  const _SearchResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: const [
          _SkeletonSearchRow(),
          _SkeletonSearchRow(),
          _SkeletonSearchRow(),
        ],
      ),
    );
  }
}

class _SkeletonSearchRow extends StatelessWidget {
  const _SkeletonSearchRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SkeletonBox(width: 64, height: 92, radius: 8),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 160, height: 14),
                SizedBox(height: 10),
                SkeletonLine(width: 220, height: 10),
                SizedBox(height: 10),
                SkeletonLine(width: 70, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreSkeletonGrid extends StatelessWidget {
  const _GenreSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.75,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => const SkeletonBox(height: 54),
    );
  }
}

class _SearchResult extends StatelessWidget {
  const _SearchResult({required this.item, required this.onTap});

  final ContentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            PosterArt(
              item: item,
              width: 64,
              height: 92,
              radius: 8,
              showTitle: false,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.metadata,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: VeilColors.text3,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFBBF24),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: VeilColors.text2,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: VeilColors.text3),
          ],
        ),
      ),
    );
  }
}

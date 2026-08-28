import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/router/app_router.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/core/utils/status/status.dart';
import 'package:veil/src/features/catalog/view_model/provider_catalog_providers.dart';
import 'package:veil/src/shared/components/ads/native_ad_sliver_grid.dart';
import 'package:veil/src/shared/components/content_cards.dart';
import 'package:veil/src/shared/components/skeleton.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';
import 'package:veil/src/shared/models/content_item.dart';

enum _ProviderCatalogTab { movies, tvSeries }

class ProviderView extends ConsumerStatefulWidget {
  const ProviderView({
    super.key,
    required this.providerId,
    this.providerName,
    this.logoPath,
  });

  final int providerId;
  final String? providerName;
  final String? logoPath;

  @override
  ConsumerState<ProviderView> createState() => _ProviderViewState();
}

class _ProviderViewState extends ConsumerState<ProviderView> {
  final _scrollController = ScrollController();
  var _tab = _ProviderCatalogTab.movies;

  String get _mediaType => switch (_tab) {
    _ProviderCatalogTab.movies => 'movie',
    _ProviderCatalogTab.tvSeries => 'tv',
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaType = _mediaType;
    final provider = providerCatalogProvider(widget.providerId, mediaType);
    final catalog = ref.watch(provider);
    final name = widget.providerName?.trim();
    final resolvedName = name == null || name.isEmpty
        ? 'Provider ${widget.providerId}'
        : name;
    final logoUrl = AppEnvironment.tmdbImageUrl('w154', widget.logoPath);
    final gutter = VeilLayout.pageGutter(context);

    bool onScroll(ScrollNotification notification) {
      if (notification.depth == 0 &&
          notification.metrics.axis == Axis.vertical &&
          notification.metrics.extentAfter < 500 &&
          catalog.loadMoreError.isEmpty) {
        ref.read(provider.notifier).loadMore();
      }
      return false;
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [VeilColors.bg0, VeilColors.bg1, VeilColors.bg0],
          stops: [0, .5, 1],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          leadingWidth: 62,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const ValueKey('provider-back-button'),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: VeilColors.panel.withValues(alpha: .72),
                  side: BorderSide(color: Colors.white.withValues(alpha: .20)),
                  minimumSize: const Size.square(38),
                  maximumSize: const Size.square(38),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ),
          title: AnimatedBuilder(
            animation: _scrollController,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _CollapsedProviderIdentity(
                name: resolvedName,
                logoUrl: logoUrl,
              ),
            ),
            builder: (context, child) {
              final offset = _scrollController.hasClients
                  ? _scrollController.offset
                  : 0.0;
              final progress = (offset / 88).clamp(0.0, 1.0);
              return ExcludeSemantics(
                excluding: progress == 0,
                child: Opacity(
                  key: const ValueKey('provider-collapsed-identity'),
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - progress)),
                    child: Transform.scale(
                      alignment: Alignment.centerLeft,
                      scale: .94 + (.06 * progress),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: onScroll,
          child: CustomScrollView(
            key: const ValueKey('provider-catalog-list'),
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
                sliver: SliverToBoxAdapter(
                  child: _ProviderHeader(name: resolvedName, logoUrl: logoUrl),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverPersistentHeader(
                key: const ValueKey('provider-media-tabs-header'),
                pinned: true,
                delegate: _ProviderTabsHeaderDelegate(
                  gutter: gutter,
                  child: _ProviderTabs(
                    selected: _tab,
                    onChanged: (tab) {
                      if (tab == _tab) return;
                      setState(() => _tab = tab);
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              _ProviderCatalogState(
                tab: _tab,
                state: catalog,
                onRetry: () => ref.read(provider.notifier).loadInitial(),
              ),
              _ProviderPaginationFooter(
                state: catalog,
                onRetry: () => ref.read(provider.notifier).retryLoadMore(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderHeader extends StatelessWidget {
  const _ProviderHeader({required this.name, required this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProviderLogo(
          logoKey: const ValueKey('provider-header-logo'),
          name: name,
          logoUrl: logoUrl,
          size: 76,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Browse on',
                style: TextStyle(
                  color: VeilColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollapsedProviderIdentity extends StatelessWidget {
  const _CollapsedProviderIdentity({required this.name, required this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProviderLogo(
          logoKey: const ValueKey('provider-collapsed-logo'),
          name: name,
          logoUrl: logoUrl,
          size: 38,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderTabs extends StatelessWidget {
  const _ProviderTabs({required this.selected, required this.onChanged});

  final _ProviderCatalogTab selected;
  final ValueChanged<_ProviderCatalogTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('provider-media-tabs'),
      children: [
        Expanded(
          child: _ProviderTabButton(
            buttonKey: const ValueKey('provider-tab-movies'),
            label: 'Movies',
            selected: selected == _ProviderCatalogTab.movies,
            onTap: () => onChanged(_ProviderCatalogTab.movies),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ProviderTabButton(
            buttonKey: const ValueKey('provider-tab-tv'),
            label: 'TV Series',
            selected: selected == _ProviderCatalogTab.tvSeries,
            onTap: () => onChanged(_ProviderCatalogTab.tvSeries),
          ),
        ),
      ],
    );
  }
}

class _ProviderTabButton extends StatelessWidget {
  const _ProviderTabButton({
    required this.buttonKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : VeilColors.panelRaised,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.white : VeilColors.hairlineStrong,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : VeilColors.text2,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProviderTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ProviderTabsHeaderDelegate({
    required this.gutter,
    required this.child,
  });

  final double gutter;
  final Widget child;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 12),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _ProviderTabsHeaderDelegate oldDelegate) {
    return oldDelegate.gutter != gutter || oldDelegate.child != child;
  }
}

class _ProviderCatalogState extends StatelessWidget {
  const _ProviderCatalogState({
    required this.tab,
    required this.state,
    required this.onRetry,
  });

  final _ProviderCatalogTab tab;
  final ProviderCatalogState state;
  final VoidCallback onRetry;

  String get _title => switch (tab) {
    _ProviderCatalogTab.movies => 'Movies',
    _ProviderCatalogTab.tvSeries => 'TV Series',
  };

  String get _emptyMessage => switch (tab) {
    _ProviderCatalogTab.movies => 'No movies available in the US.',
    _ProviderCatalogTab.tvSeries => 'No TV series available in the US.',
  };

  Key get _retryKey => switch (tab) {
    _ProviderCatalogTab.movies => const ValueKey('provider-movies-retry'),
    _ProviderCatalogTab.tvSeries => const ValueKey('provider-tv-retry'),
  };

  @override
  Widget build(BuildContext context) {
    if (state.items.isNotEmpty) {
      return _ProviderCatalogGrid(items: state.items);
    }
    if (state.loadStatus is StatusInitial ||
        state.loadStatus is StatusLoading) {
      return const _ProviderCatalogSkeleton();
    }
    if (state.loadStatus is StatusFailure ||
        state.loadStatus is StatusAuthFailure) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: VeilLayout.pageGutter(context),
          vertical: 14,
        ),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Unable to load $_title.',
                  style: const TextStyle(color: VeilColors.text3),
                ),
              ),
              TextButton.icon(
                key: _retryKey,
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: VeilLayout.pageGutter(context),
        vertical: 24,
      ),
      sliver: SliverToBoxAdapter(
        child: Text(
          _emptyMessage,
          style: const TextStyle(color: VeilColors.text3),
        ),
      ),
    );
  }
}

class _ProviderCatalogGrid extends StatelessWidget {
  const _ProviderCatalogGrid({required this.items});

  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    final gutter = VeilLayout.pageGutter(context);
    return NativeAdSliverGrid<ContentItem>(
      key: const ValueKey('provider-catalog-ad-grid'),
      items: items,
      keyPrefix: 'provider',
      gridKey: const ValueKey('provider-catalog-grid'),
      padding: EdgeInsets.symmetric(horizontal: gutter),
      adPadding: EdgeInsets.fromLTRB(gutter, 20, gutter, 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: VeilLayout.posterGridColumns(context),
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        childAspectRatio: .49,
      ),
      itemBuilder: (context, item, index) {
        return PosterCard(
          key: ValueKey('provider-catalog-item-${item.id}'),
          item: item,
          width: double.infinity,
          height: 160,
          onTap: () => DetailRoute(id: item.id, $extra: item).push(context),
        );
      },
    );
  }
}

class _ProviderCatalogSkeleton extends StatelessWidget {
  const _ProviderCatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    final columns = VeilLayout.posterGridColumns(context);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: VeilLayout.pageGutter(context)),
      sliver: SliverGrid.builder(
        key: const ValueKey('provider-catalog-loading-grid'),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 20,
          crossAxisSpacing: 12,
          childAspectRatio: .49,
        ),
        itemCount: columns * 2,
        itemBuilder: (_, index) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(
              key: ValueKey('provider-catalog-loading-$index'),
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

class _ProviderPaginationFooter extends StatelessWidget {
  const _ProviderPaginationFooter({required this.state, required this.onRetry});

  final ProviderCatalogState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const SliverToBoxAdapter(
        key: ValueKey('provider-load-more-progress'),
        child: Padding(
          padding: EdgeInsets.only(top: 28, bottom: 8),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    if (state.loadMoreError.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            VeilLayout.pageGutter(context),
            20,
            VeilLayout.pageGutter(context),
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(
                child: Text(
                  'Unable to load more titles.',
                  style: TextStyle(color: VeilColors.text3),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                key: const ValueKey('provider-load-more-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}

class _ProviderLogo extends StatelessWidget {
  const _ProviderLogo({
    required this.logoKey,
    required this.name,
    required this.logoUrl,
    required this.size,
  });

  final Key logoKey;
  final String name;
  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: VeilColors.bg3,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    return Container(
      key: logoKey,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VeilColors.hairlineStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: logoUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ColoredBox(color: VeilColors.bg3),
              errorWidget: (_, _, _) => fallback,
            ),
    );
  }
}

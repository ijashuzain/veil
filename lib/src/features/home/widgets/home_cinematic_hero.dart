import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:veil/src/core/config/app_environment.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/shared/components/content_cards.dart';
import 'package:veil/src/shared/components/poster_art.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';
import 'package:veil/src/shared/models/content_item.dart';

class HomeCinematicHero extends StatefulWidget {
  const HomeCinematicHero({
    super.key,
    required this.items,
    required this.height,
    required this.unreadAlerts,
    required this.onSearch,
    required this.onAlerts,
    required this.onView,
    required this.onQuickAdd,
  });

  final List<ContentItem> items;
  final double height;
  final int unreadAlerts;
  final VoidCallback onSearch;
  final VoidCallback onAlerts;
  final ValueChanged<ContentItem> onView;
  final ValueChanged<ContentItem> onQuickAdd;

  @override
  State<HomeCinematicHero> createState() => _HomeCinematicHeroState();
}

class _HomeCinematicHeroState extends State<HomeCinematicHero> {
  static const _rotationInterval = Duration(seconds: 7);

  Timer? _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
    _precacheNextBackdrop();
  }

  @override
  void didUpdateWidget(covariant HomeCinematicHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameItems(oldWidget.items, widget.items)) return;

    _index = 0;
    _restartTimer();
    _precacheNextBackdrop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final safeIndex = _index % widget.items.length;
    final featured = widget.items[safeIndex];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      key: const ValueKey('home-cinematic-hero'),
      width: double.infinity,
      height: widget.height,
      child: AnimatedSwitcher(
        key: const ValueKey('home-hero-switcher'),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _CinematicHeroFrame(
          key: ValueKey(featured.id),
          item: featured,
          height: widget.height,
          unreadAlerts: widget.unreadAlerts,
          onSearch: widget.onSearch,
          onAlerts: widget.onAlerts,
          onView: () => widget.onView(featured),
          onQuickAdd: () => widget.onQuickAdd(featured),
        ),
      ),
    );
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.items.length < 2) return;

    _timer = Timer.periodic(_rotationInterval, (_) {
      if (!mounted || widget.items.length < 2) {
        _timer?.cancel();
        return;
      }
      setState(() => _index = (_index + 1) % widget.items.length);
      _precacheNextBackdrop();
    });
  }

  void _precacheNextBackdrop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.items.length < 2) return;
      final next = widget.items[(_index + 1) % widget.items.length];
      final source = next.backdropUrl;
      if (source == null || source.trim().isEmpty) return;
      final url = AppEnvironment.resolveTmdbImageUrl(source);
      unawaited(precacheImage(CachedNetworkImageProvider(url), context));
    });
  }

  bool _sameItems(List<ContentItem> left, List<ContentItem> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index].id != right[index].id ||
          left[index].backdropUrl != right[index].backdropUrl) {
        return false;
      }
    }
    return true;
  }
}

class _CinematicHeroFrame extends StatelessWidget {
  const _CinematicHeroFrame({
    super.key,
    required this.item,
    required this.height,
    required this.unreadAlerts,
    required this.onSearch,
    required this.onAlerts,
    required this.onView,
    required this.onQuickAdd,
  });

  final ContentItem item;
  final double height;
  final int unreadAlerts;
  final VoidCallback onSearch;
  final VoidCallback onAlerts;
  final VoidCallback onView;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final gutter = VeilLayout.pageGutter(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final desktop = VeilBreakpoint.of(context).isDesktop;
    return BackdropArt(
      item: item,
      width: double.infinity,
      height: height,
      radius: 0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: DecoratedBox(
              key: ValueKey('home-hero-horizontal-vignette'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xB3000000),
                    Color(0x18000000),
                    Color(0x10000000),
                    Color(0x99000000),
                  ],
                  stops: [0, .28, .68, 1],
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              key: ValueKey('home-hero-top-contrast'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xC7000000), Colors.transparent],
                  stops: [0, .34],
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              key: ValueKey('home-hero-bottom-blend'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xB8050507),
                    VeilColors.bg0,
                  ],
                  stops: [.38, .76, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: gutter,
            right: gutter,
            top: topInset + 12,
            child: Row(
              children: [
                ActionCircle(
                  key: const ValueKey('home-hero-search'),
                  icon: Icons.search_rounded,
                  onTap: onSearch,
                ),
                const Spacer(),
                ActionCircle(
                  key: const ValueKey('home-hero-alerts'),
                  icon: Icons.notifications_none_rounded,
                  badge: unreadAlerts > 0,
                  onTap: onAlerts,
                ),
              ],
            ),
          ),
          Positioned(
            left: gutter,
            right: gutter,
            bottom: desktop ? 54 : 38,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: desktop ? 46 : 34,
                        fontWeight: FontWeight.w900,
                        height: .94,
                        letterSpacing: desktop ? 1.2 : .7,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    _HeroMetadata(item: item),
                    if (item.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        item.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: VeilColors.text2,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 12),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          key: const ValueKey('home-hero-view'),
                          onPressed: onView,
                          icon: const Icon(Icons.visibility_outlined, size: 19),
                          label: const Text('View'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(0, 44),
                            maximumSize: const Size(double.infinity, 44),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox.square(
                          dimension: 44,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: VeilColors.panelRaised,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(
                                BorderSide(color: VeilColors.hairlineStrong),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: IconButton(
                              key: const ValueKey('home-hero-add'),
                              onPressed: onQuickAdd,
                              tooltip: 'Add to Veil',
                              icon: const Icon(Icons.add_rounded),
                              color: Colors.white,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 44,
                                height: 44,
                              ),
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetadata extends StatelessWidget {
  const _HeroMetadata({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final year = item.year > 0 ? '${item.year}' : 'TBA';
    final primaryGenre = item.genre.split('/').first.trim();
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        _MetadataItem(icon: Icons.calendar_today_outlined, label: year),
        _MetadataItem(
          icon: Icons.local_movies_outlined,
          label: primaryGenre.isEmpty ? item.type : primaryGenre,
        ),
      ],
    );
  }
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

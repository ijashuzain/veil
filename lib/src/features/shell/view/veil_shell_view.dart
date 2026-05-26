import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:veil/src/core/theme/veil_theme.dart';
import 'package:veil/src/features/home/view/home_view.dart';
import 'package:veil/src/features/profile/view/profile_view.dart';
import 'package:veil/src/features/reviews/view/reviews_view.dart';
import 'package:veil/src/features/social/view/diary_view.dart';
import 'package:veil/src/shared/layout/veil_breakpoints.dart';

class VeilShellView extends StatefulWidget {
  const VeilShellView({super.key});

  @override
  State<VeilShellView> createState() => _VeilShellViewState();
}

class _VeilShellViewState extends State<VeilShellView> {
  static const _desktopRailWidth = 88.0;
  static const _desktopRailGap = 24.0;

  var _activeIndex = 0;
  final _loadedTabs = <int>{0};

  @override
  Widget build(BuildContext context) {
    final breakpoint = VeilBreakpoint.of(context);
    return Scaffold(
      extendBody: true,
      body: breakpoint.usesRail
          ? Stack(
              children: [
                Positioned.fill(
                  left: _desktopRailWidth + _desktopRailGap,
                  child: _TabStack(activeIndex: _activeIndex),
                ),
                Positioned(
                  top: 12,
                  bottom: 12,
                  left: 12,
                  child: _DesktopGlassRail(
                    activeIndex: _activeIndex,
                    onDestinationSelected: _selectTab,
                  ),
                ),
              ],
            )
          : _TabStack(activeIndex: _activeIndex),
      bottomNavigationBar: breakpoint.isMobile
          ? SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: VeilColors.panel.withValues(alpha: .86),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: VeilColors.hairlineStrong),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .50),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var index = 0; index < _tabs.length; index++)
                          _TabButton(
                            selected: _activeIndex == index,
                            icon: _tabs[index].icon,
                            label: _tabs[index].label,
                            onTap: () => _selectTab(index),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _selectTab(int index) {
    setState(() {
      _activeIndex = index;
      _loadedTabs.add(index);
    });
  }

  Widget _tabPage(int index) {
    if (!_loadedTabs.contains(index)) return const SizedBox.shrink();
    return switch (index) {
      0 => const HomeView(),
      1 => const DiaryView(),
      2 => const ReviewsView(),
      _ => const ProfileView(),
    };
  }
}

const _tabs = [
  _ShellTab(label: 'Home', icon: Icons.home_rounded),
  _ShellTab(label: 'Diary', icon: Icons.menu_book_rounded),
  _ShellTab(label: 'Reviews', icon: Icons.rate_review_outlined),
  _ShellTab(label: 'Profile', icon: Icons.person_outline_rounded),
];

class _ShellTab {
  const _ShellTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _ShellNavigationRail extends StatelessWidget {
  const _ShellNavigationRail({
    required this.activeIndex,
    required this.onDestinationSelected,
  });

  final int activeIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: activeIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: Colors.transparent,
      indicatorColor: VeilColors.red,
      selectedIconTheme: const IconThemeData(color: Colors.black),
      unselectedIconTheme: const IconThemeData(color: VeilColors.text3),
      selectedLabelTextStyle: const TextStyle(
        color: VeilColors.gold,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: VeilColors.text3,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      labelType: NavigationRailLabelType.all,
      minWidth: 74,
      groupAlignment: -0.82,
      destinations: [
        for (final tab in _tabs)
          NavigationRailDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.icon),
            label: Text(tab.label),
          ),
      ],
    );
  }
}

class _DesktopGlassRail extends StatelessWidget {
  const _DesktopGlassRail({
    required this.activeIndex,
    required this.onDestinationSelected,
  });

  final int activeIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      right: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: 76,
            decoration: BoxDecoration(
              color: VeilColors.panel.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .16),
                  VeilColors.panel.withValues(alpha: .58),
                  Colors.black.withValues(alpha: .26),
                ],
                stops: const [0, .46, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .42),
                  blurRadius: 34,
                  offset: const Offset(14, 20),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: .08),
                  blurRadius: 10,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 1,
                  top: 1,
                  right: 1,
                  height: 92,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(29),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: .20),
                          Colors.white.withValues(alpha: .02),
                        ],
                      ),
                    ),
                  ),
                ),
                _ShellNavigationRail(
                  activeIndex: activeIndex,
                  onDestinationSelected: onDestinationSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabStack extends StatefulWidget {
  const _TabStack({required this.activeIndex});

  final int activeIndex;

  @override
  State<_TabStack> createState() => _TabStackState();
}

class _TabStackState extends State<_TabStack> {
  _VeilShellViewState get shellState {
    return context.findAncestorStateOfType<_VeilShellViewState>()!;
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.activeIndex,
      children: [
        for (var index = 0; index < _tabs.length; index++)
          shellState._tabPage(index),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : VeilColors.text3;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? VeilColors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? VeilColors.gold.withValues(alpha: .45)
                : Colors.transparent,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: VeilColors.red.withValues(alpha: .30),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

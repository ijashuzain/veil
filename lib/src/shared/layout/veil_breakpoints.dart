import 'package:flutter/widgets.dart';

enum VeilBreakpoint {
  mobile,
  tablet,
  desktop;

  static VeilBreakpoint forWidth(double width) {
    if (width >= 1024) return VeilBreakpoint.desktop;
    if (width >= 700) return VeilBreakpoint.tablet;
    return VeilBreakpoint.mobile;
  }

  static VeilBreakpoint of(BuildContext context) {
    return forWidth(MediaQuery.sizeOf(context).width);
  }

  bool get isMobile => this == VeilBreakpoint.mobile;
  bool get isTablet => this == VeilBreakpoint.tablet;
  bool get isDesktop => this == VeilBreakpoint.desktop;
  bool get usesRail => this != VeilBreakpoint.mobile;
}

class VeilLayout {
  const VeilLayout._();

  static double pageGutter(BuildContext context) {
    return switch (VeilBreakpoint.of(context)) {
      VeilBreakpoint.mobile => 20,
      VeilBreakpoint.tablet => 32,
      VeilBreakpoint.desktop => 48,
    };
  }

  static double compactPageGutter(BuildContext context) {
    return switch (VeilBreakpoint.of(context)) {
      VeilBreakpoint.mobile => 20,
      VeilBreakpoint.tablet => 28,
      VeilBreakpoint.desktop => 36,
    };
  }

  static double pageTopPadding(BuildContext context) {
    return MediaQuery.paddingOf(context).top + 14;
  }

  static double contentMaxWidth(BuildContext context) {
    return switch (VeilBreakpoint.of(context)) {
      VeilBreakpoint.mobile => double.infinity,
      VeilBreakpoint.tablet => 760,
      VeilBreakpoint.desktop => 1180,
    };
  }

  static double readableMaxWidth(BuildContext context) {
    return switch (VeilBreakpoint.of(context)) {
      VeilBreakpoint.mobile => double.infinity,
      VeilBreakpoint.tablet => 720,
      VeilBreakpoint.desktop => 860,
    };
  }

  static double detailHeroHeight(BuildContext context) {
    return switch (VeilBreakpoint.of(context)) {
      VeilBreakpoint.mobile => 480,
      VeilBreakpoint.tablet => 520,
      VeilBreakpoint.desktop => 560,
    };
  }

  static double homeHeroHeight(BuildContext context) {
    return switch (VeilBreakpoint.of(context)) {
      VeilBreakpoint.mobile => 216,
      VeilBreakpoint.tablet => 280,
      VeilBreakpoint.desktop => 320,
    };
  }

  static int posterGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1400) return 7;
    if (width >= 1100) return 6;
    if (width >= 820) return 5;
    return 3;
  }

  static int diaryGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 7;
    if (width >= 900) return 6;
    if (width >= 700) return 5;
    return 4;
  }

  static int genreGridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1120) return 4;
    if (width >= 760) return 3;
    return 2;
  }
}

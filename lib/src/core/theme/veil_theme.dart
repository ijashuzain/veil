import 'package:flutter/material.dart';

class VeilColors {
  static const red = Color(0xFFE50914);
  static const redDeep = Color(0xFFB0060F);
  static const bg0 = Color(0xFF050507);
  static const bg1 = Color(0xFF0B0B0F);
  static const bg2 = Color(0xFF14141A);
  static const bg3 = Color(0xFF1C1C24);
  static const bg4 = Color(0xFF26262F);
  static const panel = Color(0xFF111217);
  static const panelRaised = Color(0xFF191A21);
  static const redSoft = Color(0x33E50914);
  static const gold = Color(0xFFE2B15B);
  static const goldMuted = Color(0x995E4A24);
  static const text1 = Colors.white;
  static const text2 = Color(0xB8FFFFFF);
  static const text3 = Color(0x80FFFFFF);
  static const text4 = Color(0x52FFFFFF);
  static const hairline = Color(0x14FFFFFF);
  static const hairlineStrong = Color(0x24FFFFFF);
}

class VeilTheme {
  static const sheetRadius = 24.0;
  static const controlRadius = 12.0;
  static const chipHeight = 34.0;

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: VeilColors.bg1,
      colorScheme: const ColorScheme.dark(
        primary: VeilColors.red,
        secondary: VeilColors.redDeep,
        surface: VeilColors.bg1,
        onSurface: VeilColors.text1,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: VeilColors.text1,
        displayColor: VeilColors.text1,
        fontFamily: 'SF Pro Display',
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: VeilColors.bg1,
        indicatorColor: VeilColors.red,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

extension VeilText on BuildContext {
  TextStyle get display => const TextStyle(
    color: VeilColors.text1,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 1,
  );

  TextStyle get sectionTitle => const TextStyle(
    color: VeilColors.text1,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
}

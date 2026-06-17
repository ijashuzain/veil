import 'package:flutter/material.dart';

class VeilColors {
  static const red = Color(0xFFF5C84B);
  static const redDeep = Color(0xFF806515);
  static const bg0 = Color(0xFF050507);
  static const bg1 = Color(0xFF090D0F);
  static const bg2 = Color(0xFF111719);
  static const bg3 = Color(0xFF182124);
  static const bg4 = Color(0xFF253034);
  static const panel = Color(0xFF101617);
  static const panelRaised = Color(0xFF192123);
  static const redSoft = Color(0x33F5C84B);
  static const gold = Color(0xFFF5C84B);
  static const goldMuted = Color(0x665F4714);
  static const teal = Color(0xFF4FD1C5);
  static const text1 = Colors.white;
  static const text2 = Color(0xCCFFFFFF);
  static const text3 = Color(0x91FFFFFF);
  static const text4 = Color(0x61FFFFFF);
  static const hairline = Color(0x1FFFFFFF);
  static const hairlineStrong = Color(0x33FFFFFF);
}

class VeilTheme {
  static const sheetRadius = 24.0;
  static const controlRadius = 16.0;
  static const cardRadius = 22.0;
  static const chipHeight = 34.0;

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: VeilColors.bg1,
      colorScheme: const ColorScheme.dark(
        primary: VeilColors.red,
        secondary: VeilColors.gold,
        surface: VeilColors.bg1,
        surfaceTint: Colors.transparent,
        onSurface: VeilColors.text1,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: VeilColors.text1,
        displayColor: VeilColors.text1,
        fontFamily: 'SF Pro Display',
      ),
      dividerColor: VeilColors.hairline,
      splashColor: VeilColors.redSoft,
      highlightColor: Colors.white10,
      cardTheme: CardThemeData(
        color: VeilColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VeilColors.panel,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VeilColors.panelRaised,
        hintStyle: const TextStyle(color: VeilColors.text3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: VeilColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: VeilColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: VeilColors.red),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: VeilColors.red,
          foregroundColor: Colors.black,
          disabledBackgroundColor: VeilColors.redDeep,
          disabledForegroundColor: Colors.white70,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: VeilColors.gold),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VeilColors.red,
        contentTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: VeilColors.bg1,
        indicatorColor: VeilColors.redSoft,
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
    fontSize: 19,
    fontWeight: FontWeight.w900,
    letterSpacing: -.2,
  );
}

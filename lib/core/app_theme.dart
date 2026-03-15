import 'package:flutter/material.dart';

const surfaceColor = Color(0xFFF3F5F9);
const cardColor = Colors.white;
const inkColor = Color(0xFF071634);
const mutedText = Color(0xFF8692A6);
const lineColor = Color(0xFFDCE2EE);
const accentColor = Color(0xFF2F67E8);
const accentSoft = Color(0xFFE8F0FF);
const successColor = Color(0xFF1FAA59);
const dangerColor = Color(0xFFE25757);
const offlineFill = Color(0xFFFFF2C8);
const offlineText = Color(0xFFB56A00);
const darkSurfaceColor = Color(0xFF07111F);
const darkCardColor = Color(0xFF0F1C2E);
const darkLineColor = Color(0xFF23324A);
const darkMutedText = Color(0xFFAAB7CE);
const darkInkColor = Color(0xFFF5F7FB);
const darkAccentSoft = Color(0xFF183455);
const darkAccentStrong = Color(0xFF234A7A);

Color appLineColorFor(Brightness brightness) => brightness == Brightness.dark ? darkLineColor : lineColor;
Color appMutedColorFor(Brightness brightness) => brightness == Brightness.dark ? darkMutedText : mutedText;
Color appInkColorFor(Brightness brightness) => brightness == Brightness.dark ? darkInkColor : inkColor;
Color appFieldFillColorFor(Brightness brightness) => brightness == Brightness.dark ? const Color(0xFF12253B) : const Color(0xFFF7F9FD);
Color appSelectionSurfaceFor(Brightness brightness) => brightness == Brightness.dark ? darkAccentSoft : accentSoft;
Color appSelectionSurfaceStrongFor(Brightness brightness) => brightness == Brightness.dark ? darkAccentStrong : accentSoft;
Color appSelectionForegroundFor(Brightness brightness) => brightness == Brightness.dark ? darkInkColor : accentColor;

Color appLineColor(BuildContext context) => appLineColorFor(Theme.of(context).brightness);
Color appMutedColor(BuildContext context) => appMutedColorFor(Theme.of(context).brightness);
Color appInkColor(BuildContext context) => appInkColorFor(Theme.of(context).brightness);
Color appFieldFillColor(BuildContext context) => appFieldFillColorFor(Theme.of(context).brightness);
Color appSelectionSurface(BuildContext context) => appSelectionSurfaceFor(Theme.of(context).brightness);
Color appSelectionSurfaceStrong(BuildContext context) => appSelectionSurfaceStrongFor(Theme.of(context).brightness);
Color appSelectionForeground(BuildContext context) => appSelectionForegroundFor(Theme.of(context).brightness);

ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final surface = isDark ? darkSurfaceColor : surfaceColor;
  final card = isDark ? darkCardColor : cardColor;
  final line = appLineColorFor(brightness);
  final ink = appInkColorFor(brightness);
  final muted = appMutedColorFor(brightness);
  final fieldFill = appFieldFillColorFor(brightness);
  final selectedFill = appSelectionSurfaceFor(brightness);
  final selectedFillStrong = appSelectionSurfaceStrongFor(brightness);
  final selectedFg = appSelectionForegroundFor(brightness);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: brightness,
      primary: accentColor,
      surface: surface,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: ink),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: ink),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ink),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: card,
      foregroundColor: ink,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: accentColor),
      ),
      hintStyle: TextStyle(color: muted),
    ),
    dividerColor: line,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card,
      indicatorColor: selectedFillStrong,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? selectedFg : muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected) ? selectedFg : muted,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? selectedFill : fieldFill,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? selectedFg : ink,
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: Colors.transparent)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: fieldFill,
      selectedColor: selectedFill,
      secondarySelectedColor: selectedFill,
      disabledColor: fieldFill,
      side: BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w700),
      secondaryLabelStyle: TextStyle(color: selectedFg, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

IconData themeModeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
    ThemeMode.system => Icons.brightness_auto_rounded,
  };
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Design tokens
class AppTokens {
  // Spacing
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  // Radius
  static const r8 = 8.0;
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r24 = 24.0;

  // Elevation
  static const e0 = 0.0;
  static const e1 = 1.0;
  static const e3 = 3.0;

  // Durations
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);
}

class AppBreakpoints {
  static const xs = 600.0;   // <600
  static const sm = 900.0;   // 600–900
  static const md = 1200.0;  // 900–1200
  static const lg = 1536.0;  // 1200–1536
  static const xl = 1536.0; // xl >= 1536
}

const maxContentWidth = 1200.0;

// Colors (Petshop cheerful + accessible palette)
class AppColors {
  // Core
  static const primary = Color(0xFFFF8A00); // laranja “pet”
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF19B4A3); // teal
  static const onSecondary = Color(0xFF062A27);
  static const tertiary = Color(0xFF6C5CE7); // lavanda/roxo suave
  static const onTertiary = Color(0xFFFFFFFF);

  // Surfaces
  static const background = Color(0xFFFFF8EF); // creme
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1F2937);
  static const outline = Color(0xFFD1D5DB);

  // Semantics
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Variants
  static const surfaceVariant = Color(0xFFF0F9FF); // sutil, para placeholders
}

// Currency helpers
final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
String formatBrl(num value) => _brl.format(value);

EdgeInsets appPaddingFor(double width) {
  // Wider screens get larger horizontal gutters
  if (width < AppBreakpoints.xs) return const EdgeInsets.symmetric(horizontal: 12.0);
  if (width < AppBreakpoints.sm) return const EdgeInsets.symmetric(horizontal: 16.0);
  if (width < AppBreakpoints.md) return const EdgeInsets.symmetric(horizontal: 24.0);
  if (width < AppBreakpoints.lg) return const EdgeInsets.symmetric(horizontal: 28.0);
  return const EdgeInsets.symmetric(horizontal: 32.0);
}

int gridCrossAxisCountFor(double width) {
  if (width < AppBreakpoints.xs) return 2; // xs
  if (width < AppBreakpoints.sm) return 3; // sm
  if (width < AppBreakpoints.md) return 4; // md
  if (width < AppBreakpoints.lg) return 5; // lg
  return 5; // xl
}

// New helpers (non-breaking additions)
int gridColsFor(double width) {
  if (width >= AppBreakpoints.lg) return 5;
  if (width >= AppBreakpoints.md) return 4;
  if (width >= AppBreakpoints.sm) return 3;
  return 2;
}

double heroAspectFor(double width) {
  if (width >= AppBreakpoints.xl) return 16 / 5;
  if (width >= AppBreakpoints.lg) return 16 / 6;
  if (width >= AppBreakpoints.md) return 16 / 7;
  if (width >= AppBreakpoints.sm) return 16 / 9;
  return 4 / 3;
}

// Theme helpers
ThemeData buildLightTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    error: AppColors.error,
    onError: Colors.white,
    background: AppColors.background,
    onBackground: AppColors.onSurface,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    outline: AppColors.outline,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.light,
    scaffoldBackgroundColor: scheme.background,
    canvasColor: scheme.background,
    visualDensity: VisualDensity.standard,
  );

  final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
    titleMedium: GoogleFonts.nunito(textStyle: base.textTheme.titleMedium)?.copyWith(height: 1.3),
    titleLarge: GoogleFonts.nunito(textStyle: base.textTheme.titleLarge)?.copyWith(height: 1.3, fontWeight: FontWeight.w700),
    bodyMedium: GoogleFonts.nunito(textStyle: base.textTheme.bodyMedium)?.copyWith(height: 1.45),
    bodyLarge: GoogleFonts.nunito(textStyle: base.textTheme.bodyLarge)?.copyWith(height: 1.45),
  );

  final rounded16 = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppTokens.r16)));

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 1,
      shadowColor: scheme.onSurface.withOpacity(0.06),
    ),
    textTheme: textTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(120, 40)),
        maximumSize: const MaterialStatePropertyAll(Size(220, 48)),
        shape: MaterialStatePropertyAll(rounded16),
        elevation: const MaterialStatePropertyAll(AppTokens.e1),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return scheme.primary.withOpacity(0.12);
          if (states.contains(WidgetState.hovered)) return scheme.primary.withOpacity(0.08);
          return null;
        }),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(120, 40)),
        maximumSize: const MaterialStatePropertyAll(Size(220, 48)),
        shape: MaterialStatePropertyAll(rounded16),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return scheme.primary.withOpacity(0.12);
          if (states.contains(WidgetState.hovered)) return scheme.primary.withOpacity(0.08);
          return null;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(120, 40)),
        maximumSize: const MaterialStatePropertyAll(Size(220, 48)),
        shape: MaterialStatePropertyAll(rounded16),
        side: MaterialStatePropertyAll(BorderSide(color: scheme.outline)),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return scheme.primary.withOpacity(0.06);
          if (states.contains(WidgetState.hovered)) return scheme.primary.withOpacity(0.04);
          return null;
        }),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.secondary.withOpacity(0.10),
      selectedColor: AppColors.secondary,
      labelStyle: TextStyle(color: scheme.onSecondary, fontWeight: FontWeight.w700),
      deleteIconColor: scheme.onSecondary,
      side: BorderSide(color: scheme.outline.withOpacity(0.8)),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12, vertical: AppTokens.s8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.s16, vertical: AppTokens.s12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.r12), borderSide: BorderSide(color: scheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.r12), borderSide: BorderSide(color: scheme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.r12), borderSide: BorderSide(color: scheme.primary, width: 2)),
      labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
      hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: AppTokens.e1,
      shadowColor: scheme.onSurface.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.r16)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(AppTokens.s8),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: scheme.onSurface, borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: scheme.surface),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.onSurface,
      contentTextStyle: TextStyle(color: scheme.surface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
      textStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFFF9A26),
    onPrimary: AppColors.onPrimary,
    secondary: const Color(0xFF27C9B7),
    onSecondary: AppColors.onSecondary,
    tertiary: const Color(0xFF7B6CF0),
    onTertiary: AppColors.onTertiary,
    error: const Color(0xFFF87171),
    onError: Colors.white,
    background: const Color(0xFF0F172A),
    onBackground: const Color(0xFFE5E7EB),
    surface: const Color(0xFF111827),
    onSurface: const Color(0xFFE5E7EB),
    outline: const Color(0xFF374151),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: scheme.background,
    canvasColor: scheme.background,
    visualDensity: VisualDensity.standard,
  );

  final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
    titleMedium: GoogleFonts.nunito(textStyle: base.textTheme.titleMedium)?.copyWith(height: 1.3),
    titleLarge: GoogleFonts.nunito(textStyle: base.textTheme.titleLarge)?.copyWith(height: 1.3, fontWeight: FontWeight.w600),
    bodyMedium: GoogleFonts.nunito(textStyle: base.textTheme.bodyMedium)?.copyWith(height: 1.45),
    bodyLarge: GoogleFonts.nunito(textStyle: base.textTheme.bodyLarge)?.copyWith(height: 1.45),
  );

  final rounded16 = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppTokens.r16)));

  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      centerTitle: true,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 1,
      shadowColor: scheme.onSurface.withOpacity(0.3),
    ),
    textTheme: textTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(120, 40)),
        maximumSize: const MaterialStatePropertyAll(Size(220, 48)),
        shape: MaterialStatePropertyAll(rounded16),
        elevation: const MaterialStatePropertyAll(AppTokens.e1),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return scheme.primary.withOpacity(0.18);
          if (states.contains(WidgetState.hovered)) return scheme.primary.withOpacity(0.10);
          return null;
        }),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(120, 40)),
        maximumSize: const MaterialStatePropertyAll(Size(220, 48)),
        shape: MaterialStatePropertyAll(rounded16),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return scheme.primary.withOpacity(0.18);
          if (states.contains(WidgetState.hovered)) return scheme.primary.withOpacity(0.10);
          return null;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const MaterialStatePropertyAll(Size(120, 40)),
        maximumSize: const MaterialStatePropertyAll(Size(220, 48)),
        shape: MaterialStatePropertyAll(rounded16),
        side: MaterialStatePropertyAll(BorderSide(color: scheme.outline)),
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return scheme.primary.withOpacity(0.14);
          if (states.contains(WidgetState.hovered)) return scheme.primary.withOpacity(0.08);
          return null;
        }),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.secondary.withOpacity(0.18),
      selectedColor: AppColors.secondary,
      labelStyle: TextStyle(color: scheme.onSecondary),
      side: BorderSide(color: scheme.outline),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s12, vertical: AppTokens.s8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.s16, vertical: AppTokens.s12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.r12), borderSide: BorderSide(color: scheme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.r12), borderSide: BorderSide(color: scheme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.r12), borderSide: BorderSide(color: scheme.primary, width: 2)),
      labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.9)),
      hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
    ),
  cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: AppTokens.e1,
      shadowColor: scheme.onSurface.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.r16)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(AppTokens.s8),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
      textStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

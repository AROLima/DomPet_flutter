import 'package:flutter/material.dart';

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
  static const xs = 600.0;
  static const sm = 900.0;
  static const md = 1200.0;
  static const lg = 1536.0;
  static const xl = 1536.0; // xl >= 1536
}

const maxContentWidth = 1200.0;

// Colors (AA accessible friendly palette around teal/neutral)
class AppColors {
  static const primary = Color(0xFF0F766E); // teal-700
  static const primaryContainer = Color(0xFF115E59);
  static const onPrimary = Colors.white;

  static const neutral = Color(0xFF1F2937); // gray-800
  static const surface = Color(0xFFF8FAFC); // slate-50
  static const surfaceVariant = Color(0xFFE2E8F0); // slate-200
}

EdgeInsets appPaddingFor(double width) {
  // Wider screens get larger horizontal gutters
  if (width < AppBreakpoints.xs) return const EdgeInsets.symmetric(horizontal: 12.0);
  if (width < AppBreakpoints.sm) return const EdgeInsets.symmetric(horizontal: 16.0);
  if (width < AppBreakpoints.md) return const EdgeInsets.symmetric(horizontal: 20.0);
  if (width < AppBreakpoints.lg) return const EdgeInsets.symmetric(horizontal: 24.0);
  return const EdgeInsets.symmetric(horizontal: 28.0);
}

int gridCrossAxisCountFor(double width) {
  if (width < AppBreakpoints.xs) return 2; // xs
  if (width < AppBreakpoints.sm) return 3; // sm
  if (width < AppBreakpoints.md) return 4; // md
  if (width < AppBreakpoints.lg) return 5; // lg
  return 5; // xl
}

// Theme helpers
ThemeData buildLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.primary,
    brightness: Brightness.light,
  );
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVariant,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(120, 40)),
        maximumSize: MaterialStateProperty.all(const Size(220, 48)),
        tapTargetSize: MaterialTapTargetSize.padded,
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primary.withOpacity(0.08);
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withOpacity(0.12);
          }
          return null;
        }),
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.neutral,
      displayColor: AppColors.neutral,
    ).copyWith(
      titleMedium: base.textTheme.titleMedium?.copyWith(height: 1.3),
      titleLarge: base.textTheme.titleLarge?.copyWith(height: 1.3, fontWeight: FontWeight.w600),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
    ),
    cardTheme: const CardThemeData(
      elevation: AppTokens.e1,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.all(AppTokens.s8),
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.primary,
    brightness: Brightness.dark,
  );
  return base.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(120, 40)),
        maximumSize: MaterialStateProperty.all(const Size(220, 48)),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    textTheme: base.textTheme.copyWith(
      titleMedium: base.textTheme.titleMedium?.copyWith(height: 1.3),
      titleLarge: base.textTheme.titleLarge?.copyWith(height: 1.3, fontWeight: FontWeight.w600),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
    ),
  );
}

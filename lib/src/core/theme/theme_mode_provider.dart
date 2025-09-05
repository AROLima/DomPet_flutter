import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Simple ThemeMode state (in-memory). Non-breaking: defaults to system.
// Can later be persisted with SharedPreferences/hive without changing callers.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light); // inicia em claro explicitamente

  void toggle() => state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

  void setMode(ThemeMode mode) => state = mode == ThemeMode.system ? ThemeMode.light : mode;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

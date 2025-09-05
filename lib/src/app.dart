// DIDACTIC: App entrypoint widget
//
// Purpose:
// - Provides the global MaterialApp with themes and the router configuration.
//
// Contract:
// - Inputs: Riverpod-provided router instance (`appRouterProvider`) and
//   theme builders from the design system.
// - Output: a configured `MaterialApp.router` used as the app root widget.
//
// Notes:
// - Keep this widget minimal and side-effect free to ease testing.
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'router.dart';
import '../ui/design_system.dart';
import 'core/theme/theme_mode_provider.dart';

class AppWidget extends ConsumerWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Router is provided via Riverpod for testability and easy mocking.
    final router = ref.watch(appRouterProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DomPet',
      themeMode: themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      routerConfig: router,
    );
  }
}

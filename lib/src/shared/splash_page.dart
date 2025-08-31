// DIDACTIC: SplashPage — lightweight app entry screen
//
// Purpose:
// - Provide a minimal startup UI while the app initializes (config, session
//   restore, remote configuration fetches).
//
// Contract:
// - Inputs: app startup state (config/session ready signals).
// - Outputs: navigation to appropriate initial route (home or login).
//
// Notes:
// - Keep animations short and avoid blocking startup for long network calls.

// Simple splash page used as initial route.
// Contract:
// - Shows a loading indicator while the router navigates to the real entry
//   route. Kept minimal to avoid side-effects during app startup and tests.
// Edge cases:
// - Avoid performing heavy async work here; use providers or services so the
//   router remains snappy.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go('/');
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

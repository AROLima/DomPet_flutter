// DIDACTIC: SectionHeader — small reusable UI for section titles
//
// Purpose:
// - Render a standardized section title with optional action (See all).
//
// Contract:
// - Inputs: title text and optional onTap callback for the action.
// - Outputs: a fully accessible row with semantics for screen readers.
//
// Notes:
// - Keep styling minimal and theme-driven so it adapts to dark/light modes.

// Small reusable section header used across the app for list titles.
// Contract:
// - Pure visual widget that displays a title and optional action button.
// - Keep it simple to maximize reusability across screens.

import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionText, this.onAction});
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (actionText != null)
            TextButton(onPressed: onAction, child: Text(actionText!)),
        ],
      ),
    );
  }
}

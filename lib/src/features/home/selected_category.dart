// DIDACTIC: SelectedCategory — small helper state for the Home screen
//
// Purpose:
// - Represent the currently selected category and provide comparators/helpers
//   for UI components to adapt their filtering.
//
// Contract:
// - Inputs: optional category id or slug.
// - Outputs: category label and filtering predicate used by product sections.
//
// Notes:
// - Keep this file lightweight; business logic about categories belongs in
//   the ProductsService or in a provider.

import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Holds the currently selected category for the Home experience.
/// null means "all categories".
// Simple provider holding the currently selected home category filter.
// Using a StateProvider makes it easy for multiple widgets to react to
// category changes without prop drilling.
// Selected category state used by HomeShell and other home components.
// Contract:
// - Simple global state (nullable string) representing the active category
//   filter. Kept intentionally minimal; UI reacts to changes and triggers
//   provider-based reloads.
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

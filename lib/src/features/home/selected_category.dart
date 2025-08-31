import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Holds the currently selected category for the Home experience.
/// null means "all categories".
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

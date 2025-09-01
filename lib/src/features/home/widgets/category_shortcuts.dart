// DIDACTIC: CategoryShortcuts — quick category navigation UI
//
// Purpose:
// - Render a row of category shortcuts that update the selected category state
//   when tapped.
//
// Contract:
// - Inputs: list of category labels and a tap handler.
// - Outputs: selection callbacks and optional analytics events.
//
// Notes:
// - Keep the widget stateless if possible; manage selection in the parent or
//   in a provider so it can be preserved across navigation.

// Small UI for category shortcuts used on the home page.
// Contract:
// - Fetches categories via `categoriasProvider`; shows sensible defaults while
//   loading or on error to keep the panel stable.
// Edge cases:
// - Icon mapping is heuristic-based and intentionally forgiving for display.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../ui/design_system.dart';
import '../../products/products_service.dart';
class CategoryShortcuts extends ConsumerWidget {
  const CategoryShortcuts({super.key, this.selected, required this.onChanged});
  final String? selected;
  final void Function(String? categoria) onChanged;

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
  // Material icon mapping for common categories
  if (n.contains('cachorr') || n.contains('gato') || n.contains('pet')) return Icons.pets_outlined;
  if (n.contains('pássar') || n.contains('passar')) return Icons.emoji_nature_outlined;
  if (n.contains('peixe')) return Icons.waves_outlined;

  // Backend category labels mapping (defensive contains checks)
  if (n.contains('ração') || n.contains('racao')) return Icons.restaurant_outlined;
  if (n.contains('higien')) return Icons.cleaning_services_outlined;
  if (n.contains('medic')) return Icons.medical_services_outlined;
  if (n.contains('acess')) return Icons.shopping_bag_outlined;
  if (n.contains('brinqu')) return Icons.toys_outlined;
  if (n.contains('outdoor') || n.contains('passeio') || n.contains('parque')) return Icons.park_outlined;

  return Icons.pets_outlined; // sensible default
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriasProvider);
    final w = MediaQuery.of(context).size.width;
    final cols = gridColsFor(w);
    return catsAsync.when(
      loading: () {
        // Show static defaults while loading so the panel doesn't disappear
        const items = <String>['Cachorro', 'Gato', 'Pássaros', 'Peixes'];
        if (cols <= 3) {
          return SizedBox(
            height: 120,
            child: ListView.separated(
    // While categories load, show a sensible default so the UI remains
    // stable instead of showing an empty panel.
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (_, i) => _CatCard(
                title: items[i],
                icon: _iconFor(items[i]),
                selected: selected == items[i],
                onTap: () => onChanged(selected == items[i] ? null : items[i]),
              ),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: items.length,
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3.2,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _CatCard(
            title: items[i],
            icon: _iconFor(items[i]),
            selected: selected == items[i],
            onTap: () => onChanged(selected == items[i] ? null : items[i]),
          ),
        );
      },
      error: (e, st) {
        // On error, keep the same defaults
        const items = <String>['Cachorro', 'Gato', 'Pássaros', 'Peixes'];
        if (cols <= 3) {
          return SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (_, i) => _CatCard(
                title: items[i],
                icon: _iconFor(items[i]),
                selected: selected == items[i],
                onTap: () => onChanged(selected == items[i] ? null : items[i]),
              ),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: items.length,
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3.2,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _CatCard(
            title: items[i],
            icon: _iconFor(items[i]),
            selected: selected == items[i],
            onTap: () => onChanged(selected == items[i] ? null : items[i]),
          ),
        );
      },
      data: (cats) {
        final items = cats.isEmpty
            ? const <String>['Cachorro', 'Gato', 'Pássaros', 'Peixes']
            : cats;
        if (cols <= 3) {
          return SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (_, i) {
                final label = items[i];
                return _CatCard(
                  title: label,
                  icon: _iconFor(label),
                  selected: selected == label,
                  onTap: () => onChanged(selected == label ? null : label),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: items.length,
            ),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3.2,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final label = items[i];
            return _CatCard(
              title: label,
              icon: _iconFor(label),
              selected: selected == label,
              onTap: () => onChanged(selected == label ? null : label),
            );
          },
        );
      },
    );
  }
}

class _CatCard extends StatelessWidget {
  const _CatCard({required this.title, required this.icon, required this.onTap, this.selected = false});
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sel = selected;
    final selectedBg = isDark ? scheme.secondary.withOpacity(0.45) : scheme.secondary.withOpacity(0.12);
    final selectedFg = isDark ? Colors.white : scheme.onSecondary;
    return Material(
      color: sel ? selectedBg : scheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            // In horizontal lists the width is unbounded; shrink-wrap to avoid
            // Expanded/Infinity conflicts and let children take only what they need.
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: sel ? selectedFg : scheme.onSurface.withOpacity(0.9)),
              const SizedBox(width: 12),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: sel ? selectedFg : null,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

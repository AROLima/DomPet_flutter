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
    if (n.contains('cachorr')) return Icons.pets;
    if (n.contains('gato')) return Icons.pets_outlined;
    if (n.contains('pássar') || n.contains('passar')) return Icons.filter_vintage_outlined;
    if (n.contains('peixe')) return Icons.water_outlined;
    if (n.contains('casa') || n.contains('jardim')) return Icons.home_outlined;
    return Icons.category_outlined;
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
    final sel = selected;
    return Material(
      color: sel ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: sel ? scheme.onPrimaryContainer : null),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: sel ? scheme.onPrimaryContainer : null,
                        fontWeight: sel ? FontWeight.w700 : null,
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

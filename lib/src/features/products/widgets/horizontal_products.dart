import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../ui/design_system.dart';
import '../products_service.dart';
import '../../../shared/models/product.dart';
import 'product_card.dart';

class HorizontalProducts extends ConsumerWidget {
  const HorizontalProducts({super.key, required this.title, this.sort, this.size = 12, this.category});
  final String title;
  final String? sort; // e.g., 'vendidos,desc' or 'id,desc'
  final int size;
  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fut = ref.watch(_provider((sort, size, category)));
    return fut.when(
      data: (items) => _Body(title: title, items: items),
      loading: () => _Skeleton(title: title),
      error: (e, st) => _ErrorBox(title: title, error: e),
    );
  }
}

final _provider = FutureProvider.family<List<Produto>, (String?, int, String?)>((ref, key) async {
  final (sort, size, category) = key;
  final svc = ref.read(productsServiceProvider);
  try {
    final res = await svc.search(page: 0, size: size, sort: sort, categoria: category);
    return res.content;
  } catch (e) {
    // Safeguard: fall back to getAll to avoid empty sections on transient backend errors
    try {
      final all = await svc.getAll();
      return all.take(size).toList();
    } catch (_) {
      rethrow;
    }
  }
});

class _Body extends StatelessWidget {
  const _Body({required this.title, required this.items});
  final String title;
  final List<Produto> items;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = gridColsFor(w);
    if (cols <= 3) {
      // Horizontal list for mobile
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 310,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              scrollDirection: Axis.horizontal,
        itemBuilder: (c, i) => SizedBox(
                width: 220,
                child: ProductCard(
                  product: items[i],
          onView: () => c.push('/produto/${items[i].id}'),
                ),
              ),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: items.length,
            ),
          ),
        ],
      );
    }

    // Grid for md+
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3 / 4,
          ),
          itemCount: items.length,
          itemBuilder: (c, i) => ProductCard(
            product: items[i],
            onView: () => c.push('/produto/${items[i].id}'),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = gridColsFor(w);
    final count = cols <= 3 ? 6 : cols * 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(count, (i) => _Box()),
        )
      ],
    );
  }
}

class _Box extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.title, required this.error});
  final String title;
  final Object error;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Não foi possível carregar esta sessão agora. Tente novamente em instantes.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

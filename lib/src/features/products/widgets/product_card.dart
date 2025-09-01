// DIDACTIC: ProductCard — reusable product presentation
//
// Purpose:
// - Render a product tile used across lists, carousels and grids and expose
//   primary actions (view, add to cart) with accessible interactions.
//
// Contract:
// - Inputs: `Produto` instance and optional `onView` callback.
// - Side effects: calls `CartController.addToCart` and handles `MergeConflict`.
// - Error modes: displays disabled controls for out-of-stock items, shows
//   SnackBars for success/failure.
//
// Accessibility:
// - Uses `FocusTraversalGroup` and proper tap/focus feedback to support
//   keyboard/mouse users.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../cart/cart_service.dart';
import '../../cart/local_cart.dart' show MergeConflict;
import '../../../shared/models/product.dart';

// Reusable product card used across home / lists.
// Accessibility: uses InkWell + FocusTraversalGroup to keep keyboard and
// mouse interactions consistent. The `Adicionar` button describes optimistic
// interactions via SnackBars and handles MergeConflict thrown by remote cart
// operations.
class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({super.key, required this.product, this.onView});
  final Produto product;
  final VoidCallback? onView;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return FocusTraversalGroup(
      child: InkWell(
        onTap: widget.onView,
        borderRadius: BorderRadius.circular(12),
        mouseCursor: SystemMouseCursors.click,
        focusColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.04),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(builder: (context, constraints) {
              final tight = constraints.maxWidth < 220;
              return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: p.imagemUrl != null
                        ? Image.network(p.imagemUrl!, fit: BoxFit.cover)
                        : Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('R\$ ${p.preco.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (tight)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: (_loading || p.estoque <= 0)
                              ? null
                              : () async {
                                  setState(() => _loading = true);
                                  try {
                                    await ref.read(cartControllerProvider).addToCart(
                                          produtoId: p.id,
                                          nome: p.nome,
                                          preco: p.preco,
                                        );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicionado ao carrinho')));
                                  } on MergeConflict {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estoque insuficiente')));
                                  } finally {
                                    if (mounted) setState(() => _loading = false);
                                  }
                                },
                          child: _loading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Adicionar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: widget.onView,
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Ver',
                      )
                    ],
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: 160,
                        child: FilledButton(
                          onPressed: (_loading || p.estoque <= 0)
                              ? null
                              : () async {
                                  setState(() => _loading = true);
                                  try {
                                    await ref.read(cartControllerProvider).addToCart(
                                          produtoId: p.id,
                                          nome: p.nome,
                                          preco: p.preco,
                                        );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicionado ao carrinho')));
                                  } on MergeConflict {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estoque insuficiente')));
                                  } finally {
                                    if (mounted) setState(() => _loading = false);
                                  }
                                },
                          child: _loading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Adicionar'),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: widget.onView,
                          child: const Text('Ver'),
                        ),
                      ),
                    ],
                  ),
              ],
            );
            }),
          ),
        ),
      ),
    );
  }
}

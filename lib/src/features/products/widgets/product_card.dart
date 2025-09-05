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
import '../../../../ui/design_system.dart';
import '../../../shared/widgets/product_image.dart';

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
  focusColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
  hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tight = constraints.maxWidth < 220;
              final veryTight = constraints.maxHeight < 220 || constraints.maxWidth < 140;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: veryTight ? 4 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reverted to original aspect ratios with explicit contain fit.
                    ProductImage(
                      url: p.imagemUrl,
                      aspectRatio: veryTight ? 16 / 9 : 16 / 11,
                      fitMode: BoxFit.contain,
                      borderRadius: BorderRadius.circular(12),
                      padding: EdgeInsets.all(veryTight ? 2 : 4),
                      cacheWidth: 520,
                      cacheHeight: 520,
                      semanticLabel: p.nome,
                      errorIcon: const Icon(Icons.pets),
                    ),
                    SizedBox(height: veryTight ? 3 : 8),
                    Text(
                      p.nome,
                      maxLines: veryTight ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: (veryTight
                              ? Theme.of(context).textTheme.titleSmall
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(height: veryTight ? 1.1 : null),
                    ),
                    SizedBox(height: veryTight ? 2 : 4),
                    Text(
                      formatBrl(p.preco),
                      style: (veryTight
                              ? Theme.of(context).textTheme.titleSmall
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(height: veryTight ? 1.0 : null),
                    ),
                    if (!veryTight) const Spacer() else SizedBox(height: tight ? 3 : 6),
                    if (tight)
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: Size(0, veryTight ? 26 : 36),
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: veryTight ? 5 : 10),
                              ),
                              onPressed: (_loading || p.estoque <= 0)
                                  ? null
                                  : () async {
                                      setState(() => _loading = true);
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        await ref.read(cartControllerProvider).addToCart(
                                              produtoId: p.id,
                                              nome: p.nome,
                                              preco: p.preco,
                                            );
                                        if (!mounted) return;
                                        messenger.showSnackBar(const SnackBar(content: Text('Adicionado ao carrinho')));
                                      } on MergeConflict {
                                        if (!mounted) return;
                                        messenger.showSnackBar(const SnackBar(content: Text('Estoque insuficiente')));
                                      } finally {
                                        if (mounted) setState(() => _loading = false);
                                      }
                                    },
                              child: _loading
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Adicionar'),
                            ),
                          ),
                          SizedBox(width: veryTight ? 6 : 8),
                          IconButton(
                            onPressed: widget.onView,
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Ver',
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            constraints: BoxConstraints.tightFor(width: veryTight ? 30 : 40, height: veryTight ? 24 : 36),
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
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onPressed: (_loading || p.estoque <= 0)
                                  ? null
                                  : () async {
                                      setState(() => _loading = true);
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        await ref.read(cartControllerProvider).addToCart(
                                              produtoId: p.id,
                                              nome: p.nome,
                                              preco: p.preco,
                                            );
                                        if (!mounted) return;
                                        messenger.showSnackBar(const SnackBar(content: Text('Adicionado ao carrinho')));
                                      } on MergeConflict {
                                        if (!mounted) return;
                                        messenger.showSnackBar(const SnackBar(content: Text('Estoque insuficiente')));
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
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onPressed: widget.onView,
                              child: const Text('Ver'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

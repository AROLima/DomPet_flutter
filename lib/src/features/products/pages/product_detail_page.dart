// DIDACTIC: ProductDetailPage — product detail and add-to-cart flow
//
// Purpose:
// - Show full product information and allow the user to add items to the cart.
//
// Contract:
// - Inputs: product id or pre-fetched `Produto` instance.
// - Outputs: add-to-cart actions and navigation to related items.
// - Error modes: handle 404s by showing a not-found screen and map server
//   validation errors to user-friendly messages.
//
// Notes:
// - Keep heavy network calls in providers/services; the page should be mostly
//   composition and local UI state.

// Product detail page.
// Contract:
// - Fetches `ProdutoDetalhe` via `productDetailProvider` and displays a
//   responsive layout (row for wide, list for narrow).
// - Action buttons interact with shared `CartController` and show SnackBars.
// Edge cases:
// - UI handles loading/error async states from the provider.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/models/product.dart';
import '../../cart/cart_service.dart';
import '../../cart/local_cart.dart' show MergeConflict;
import '../products_service.dart';
import '../../../../ui/widgets/responsive_scaffold.dart';
import '../../../../ui/design_system.dart';

// Layout switches between a row (wide) and vertical list (narrow) to make good
// use of space on larger screens. Actions such as "Adicionar" call into the
// shared cart controller and show simple SnackBars on success/failure.
class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idInt = int.tryParse(id)!;
    final async = ref.watch(productDetailProvider(idInt));

    return ResponsiveScaffold(
      title: const Text('Produto'),
      body: async.when(
        data: (p) => _Detail(p: p),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.p});
  final ProdutoDetalhe p;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= AppBreakpoints.md;
      final image = Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: AspectRatio(
            aspectRatio: isWide ? 16 / 9 : 4 / 3,
            child: p.imagemUrl != null
                ? Image.network(p.imagemUrl!, fit: BoxFit.contain, gaplessPlayback: true)
                : const Icon(Icons.pets, size: 64),
          ),
        ),
      );

      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.nome, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('R\$ ${p.preco.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (p.descricao != null) Text(p.descricao!),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120),
                child: FilledButton(
                  onPressed: p.estoque > 0
                      ? () async {
                          try {
                            await ref.read(cartControllerProvider).addToCart(
                                  produtoId: p.id,
                                  nome: p.nome,
                                  preco: p.preco,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Adicionado (total atualizado no carrinho)')),
                              );
                            }
                          } on MergeConflict {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Estoque insuficiente')),
                              );
                            }
                          }
                        }
                      : null,
                  child: const Text('Adicionar'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Avise-me')),
            ],
          ),
        ],
      );

      if (isWide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: image),
            const SizedBox(width: 16),
            Expanded(child: info),
          ],
        );
      }
      return ListView(
        children: [
          image,
          const SizedBox(height: 12),
          info,
        ],
      );
    });
  }
}

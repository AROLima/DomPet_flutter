// DIDACTIC: CartPage — cart review and checkout entry
//
// Purpose:
// - Let users review cart items, change quantities, and proceed to checkout.
//
// Contract:
// - Inputs: cart provider state and item update callbacks.
// - Outputs: navigation to checkout and cart update requests.
// - Behavior: shows merge/conflict messages when server reports differences.
//
// Notes:
// - Keep optimistic UI for small quantity changes but reconcile with server
//   results and show errors when updates fail.

// Cart page UI.
// Contract:
// - Loads current cart via `CartController.fetchCart()` and supports pull-to-refresh.
// - Mutations (add/remove/update) call controller methods and then reload the view.
// Edge cases:
// - Local vs remote itemId differences are handled by controller; UI uses
//   itemId when available and falls back to produtoId for local operations.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/cart.dart';
import '../../cart/cart_service.dart';
import '../../products/products_service.dart';
import '../../../shared/widgets/product_image.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  late Future<Carrinho> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cartControllerProvider).fetchCart();
  }

  Future<void> _reload() async {
    // Avoid returning a Future from the setState callback
    setState(() {
      _future = ref.read(cartControllerProvider).fetchCart();
    });
    // Wait the reload to complete so RefreshIndicator resolves properly
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Início',
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Carrinho'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              // Capture messenger before any awaits to avoid using BuildContext across async gaps
              final messenger = ScaffoldMessenger.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Limpar carrinho'),
                  content: const Text('Remover todos os itens?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.of(dialogCtx).pop(true), child: const Text('Limpar')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(cartControllerProvider).clear();
                await _reload();
                if (mounted) {
                  messenger.showSnackBar(const SnackBar(content: Text('Carrinho limpo')));
                }
              }
            },
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Limpar'),
          ),
        ],
      ),
      body: FutureBuilder<Carrinho>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) return Center(child: Text('Erro: ${snap.error}'));
            return const Center(child: CircularProgressIndicator());
          }
          final cart = snap.data!;
          if (cart.itens.isEmpty) {
            return const Center(child: Text('Seu carrinho está vazio'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ...cart.itens.map((item) {
                  final detail = ref.watch(productDetailProvider(item.produtoId));
                  return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        onTap: () => context.push('/produto/${item.produtoId}'),
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: ClipOval(
                            child: detail.when(
                              data: (p) {
                                final url = p.imagemUrl;
                                if (url != null && url.isNotEmpty) {
                                  return ProductImage(
                                    url: url,
                                    circular: true,
                                    padding: const EdgeInsets.all(2),
                                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                    errorIcon: const Icon(Icons.pets, color: Colors.white),
                                    cacheWidth: 160,
                                    cacheHeight: 160,
                                  );
                                }
                                return ProductImage(
                                  url: null,
                                  circular: true,
                                  padding: const EdgeInsets.all(2),
                                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                  errorIcon: const Icon(Icons.pets, color: Colors.white),
                                );
                              },
                              loading: () => Container(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                alignment: Alignment.center,
                                child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              error: (e, _) => Container(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                alignment: Alignment.center,
                                child: const Icon(Icons.pets, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        title: Text(item.nome, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('R\$ ${item.precoUnitario.toStringAsFixed(2)}'),
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 168, maxWidth: 196),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.remove),
                                onPressed: () async {
                                  final q = item.quantidade - 1;
                                  if (q <= 0) {
                                    await ref.read(cartControllerProvider).remove(
                                        produtoId: item.produtoId, itemId: item.itemId >= 0 ? item.itemId : null);
                                  } else {
                                    await ref.read(cartControllerProvider).updateQty(
                                          produtoId: item.produtoId,
                                          itemId: item.itemId >= 0 ? item.itemId : null,
                                          quantidade: q,
                                          preco: item.precoUnitario,
                                          nome: item.nome,
                                        );
                                  }
                                  await _reload();
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text('${item.quantidade}', style: Theme.of(context).textTheme.titleMedium),
                              ),
                              IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  final q = item.quantidade + 1;
                                  await ref.read(cartControllerProvider).updateQty(
                                        produtoId: item.produtoId,
                                        itemId: item.itemId >= 0 ? item.itemId : null,
                                        quantidade: q,
                                        preco: item.precoUnitario,
                                        nome: item.nome,
                                      );
                                  await _reload();
                                },
                              ),
                              const SizedBox(width: 4),
                              Tooltip(
                                message: 'Remover',
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await ref.read(cartControllerProvider).remove(
                                        produtoId: item.produtoId, itemId: item.itemId >= 0 ? item.itemId : null);
                                    await _reload();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                }),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text('R\$ ${cart.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 200, maxWidth: 420),
                    child: FilledButton(
                      onPressed: () => context.push('/checkout'),
                      child: const Text('Ir para checkout'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

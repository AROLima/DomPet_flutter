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
        title: const Text('Carrinho'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Limpar carrinho'),
                  content: const Text('Remover todos os itens?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Limpar')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(cartControllerProvider).clear();
                await _reload();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carrinho limpo')));
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
                ...cart.itens.map((item) => Card(
                      child: ListTile(
                        title: Text(item.nome),
                        subtitle: Text('R\$ ' + item.precoUnitario.toStringAsFixed(2)),
                        trailing: SizedBox(
                          width: 160,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
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
                              Text('${item.quantidade}'),
                              IconButton(
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
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref.read(cartControllerProvider).remove(
                                      produtoId: item.produtoId, itemId: item.itemId >= 0 ? item.itemId : null);
                                  await _reload();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: Theme.of(context).textTheme.titleMedium),
                    Text('R\$ ' + cart.total.toStringAsFixed(2), style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.push('/checkout'),
                  child: const Text('Ir para checkout'),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(cartControllerProvider).clear();
                    await _reload();
                  },
                  child: const Text('Limpar carrinho'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

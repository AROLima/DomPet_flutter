import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../src/shared/models/product.dart';
import '../../../src/features/products/products_service.dart';
import 'admin_produto_controller.dart';
import '../widgets/admin_drawer.dart';

// AdminProdutoDeletePage — dedicated confirmation page for deleting a product
// - Shows product summary and asks for confirmation.
// - On success, navigates back to /admin/produtos with a deleted=1 flag.

class AdminProdutoDeletePage extends ConsumerWidget {
  const AdminProdutoDeletePage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(id));
    final deletingId = ref.watch(adminProdutoControllerProvider).deletingId;
    final deleting = deletingId == id;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Início',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
        title: Text('Excluir produto #$id'),
      ),
      drawer: const AdminDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: async.when(
              data: (p) => _Body(prod: p, deleting: deleting),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Erro: $e')),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.prod, required this.deleting});
  final ProdutoDetalhe prod;
  final bool deleting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) {
            _onDelete(context, ref);
            return null;
          }),
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (intent) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).maybePop();
            } else {
              context.go('/admin/produtos');
            }
            return null;
          }),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                prod.imagemUrl != null
                    ? Image.network(
                        prod.imagemUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => const Icon(Icons.pets, size: 48),
                      )
          : const Icon(Icons.pets, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(prod.nome, style: Theme.of(context).textTheme.titleLarge),
                    Text('Preço: R\$ ${prod.preco.toStringAsFixed(2)} · Estoque: ${prod.estoque}'),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Excluir produto?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Esta ação pode ser irreversível. Deseja continuar?'),
            const SizedBox(height: 24),
            Row(children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                child: OutlinedButton(
                  onPressed: deleting
                      ? null
                      : () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).maybePop();
                          } else {
                            context.go('/admin/produtos');
                          }
                        },
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                child: FilledButton.tonalIcon(
                  icon: deleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete),
                  label: const Text('Excluir'),
                  onPressed: deleting ? null : () => _onDelete(context, ref),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminProdutoControllerProvider.notifier).excluir(prod.id);
      if (!context.mounted) return;
      // Navigate with refresh parameter to trigger list reload
      context.go('/admin/produtos?deleted=1&r=${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }
}

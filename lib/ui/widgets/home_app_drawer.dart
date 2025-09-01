import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../src/core/auth/session.dart';

class HomeAppDrawer extends ConsumerWidget {
  const HomeAppDrawer({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(sessionProvider).value?.roles ?? const <String>[];
    final isAdmin = roles.contains('ADMIN') || roles.contains('ROLE_ADMIN');
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Text('DomPet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Início'),
              onTap: () => context.go('/'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () => context.push('/perfil'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Carrinho'),
              onTap: () => context.push('/cart'),
            ),
            if (isAdmin) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Admin', style: Theme.of(context).textTheme.labelLarge),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Novo Produto'),
                onTap: () => context.go('/admin/produtos/novo'),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar produto...'),
                onTap: () async {
                  final id = await _promptProdutoId(context);
                  if (id != null) {
                    if (!context.mounted) return;
                    context.go('/admin/produtos/$id/editar');
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<int?> _promptProdutoId(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar produto'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'ID do produto'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Abrir')),
        ],
      ),
    );
    if (ok == true) {
      final id = int.tryParse(ctrl.text.trim());
      return id;
    }
    return null;
  }
}

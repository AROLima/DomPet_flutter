import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../src/core/auth/session.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(sessionProvider).value?.roles ?? const <String>[];
    final isAdmin = roles.contains('ADMIN') || roles.contains('ROLE_ADMIN');
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('DomPet')),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Início'),
            onTap: () => context.go('/'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: () => context.go('/perfil'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Carrinho'),
            onTap: () => context.go('/cart'),
          ),
          if (isAdmin) const Divider(),
          if (isAdmin)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Novo Produto'),
              onTap: () => context.go('/admin/produtos/novo'),
            ),
        ],
      ),
    );
  }
}

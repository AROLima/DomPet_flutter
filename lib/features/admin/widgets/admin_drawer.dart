import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../src/core/theme/theme_mode_provider.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Text('Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Início'),
              onTap: () => context.go('/'),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Produtos'),
              onTap: () => context.go('/admin/produtos'),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Novo produto'),
              onTap: () => context.go('/admin/produtos/novo'),
            ),
            const Divider(),
            Consumer(builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              final isDark = mode == ThemeMode.dark;
              return ListTile(
                leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                title: Text(isDark ? 'Modo escuro' : 'Modo claro'),
                subtitle: const Text('Alternar tema'),
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
              );
            }),
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

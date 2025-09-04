// DIDACTIC: ProfilePage — user profile and account settings
//
// Purpose:
// - Display user profile information and provide actions like logout and
//   editing basic account details.
//
// Contract:
// - Inputs: authenticated user session and profile data provider.
// - Outputs: logout action, navigation to editing flows and order history.
//
// Notes:
// - Avoid putting heavy network logic here; use providers/services for
//   updates and optimistic UI when appropriate.

// Profile page UI.
// Contract:
// - Uses `profileProvider` to fetch the current user data and shows basic
//   fields. Keep UI read-only; editing belongs to dedicated flows.
// Edge cases:
// - Provider errors are surfaced as a simple error text; consider mapping
//   ProblemDetail for friendlier messages in the future.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/http/api_client.dart';
import '../../core/auth/session.dart';

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/usuarios/me');
  return (res.data as Map<String, dynamic>);
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Início',
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            final router = GoRouter.of(context);
            Navigator.of(context).maybePop().then((popped) {
              if (!popped) router.go('/');
            });
          },
        ),
        title: const Text('Perfil'),
      ),
      body: async.when(
        data: (json) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(json['nome']?.toString() ?? ''),
              subtitle: Text(json['email']?.toString() ?? ''),
            ),
            const SizedBox(height: 8),
            if (json['role'] != null)
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Papel'),
                subtitle: Text(json['role'].toString()),
              ),
            if (json['ativo'] != null)
              SwitchListTile(
                title: const Text('Ativo'),
                value: json['ativo'] == true,
                onChanged: null,
              ),
            const SizedBox(height: 16),
            // Admin shortcuts (visible only for ADMIN roles)
            Consumer(builder: (context, ref, _) {
              final roles = ref.watch(sessionProvider).value?.roles ?? const <String>[];
              final isAdmin = roles.contains('ADMIN') || roles.contains('ROLE_ADMIN');
              if (!isAdmin) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin', style: Theme.of(context).textTheme.titleMedium),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Gerenciar produtos'),
                    subtitle: const Text('Abrir lista de produtos (editar/excluir)'),
                    onTap: () => context.push('/admin/produtos'),
                  ),
                ],
              );
            }),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

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
import '../../core/theme/theme_mode_provider.dart';

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
  final isLoggedIn = ref.watch(sessionProvider).value != null;
  final width = MediaQuery.of(context).size.width;
  final isNarrow = width < 360;
  final tilePadding = EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 16);
  final minLead = isNarrow ? 28.0 : null;
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
          padding: EdgeInsets.fromLTRB(isNarrow ? 8 : 16, 12, isNarrow ? 8 : 16, 24),
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(json['nome']?.toString() ?? ''),
              subtitle: Text(json['email']?.toString() ?? ''),
              dense: isNarrow,
              contentPadding: tilePadding,
              minLeadingWidth: minLead,
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Meus pedidos'),
              subtitle: isNarrow ? null : const Text('Ver histórico de pedidos'),
              onTap: () => context.push('/pedidos'),
              dense: isNarrow,
              contentPadding: tilePadding,
              minLeadingWidth: minLead,
            ),
            const SizedBox(height: 8),
            // Theme toggle (agora alterna apenas Claro / Escuro)
            Consumer(builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              final isDark = mode == ThemeMode.dark;
              final icon = isDark ? Icons.dark_mode : Icons.light_mode;
              if (isNarrow) {
                return SwitchListTile.adaptive(
                  title: const Text('Tema'),
                  value: isDark,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                  secondary: Icon(icon),
                  dense: true,
                  contentPadding: tilePadding,
                );
              }
              return Padding(
                padding: tilePadding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tema'),
                        Text(
                          isDark ? 'Modo escuro ativo' : 'Modo claro ativo',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Switch.adaptive(
                      value: isDark,
                      onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            if (json['role'] != null)
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Papel'),
                subtitle: Text(json['role'].toString()),
                dense: isNarrow,
                contentPadding: tilePadding,
                minLeadingWidth: minLead,
              ),
            // Removed unused 'Ativo' switch
            const SizedBox(height: 16),
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair da conta'),
                subtitle: isNarrow ? null : const Text('Encerrar sessão neste dispositivo'),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sair?'),
                      content: const Text('Você tem certeza que deseja sair?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Sair'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  await ref.read(sessionProvider.notifier).clear();
                  if (context.mounted) {
                    context.go('/');
                  }
                },
                dense: isNarrow,
                contentPadding: tilePadding,
                minLeadingWidth: minLead,
              ),
            const SizedBox(height: 8),
            // Admin shortcuts (visible only for ADMIN roles)
            Consumer(builder: (context, ref, _) {
              final roles = ref.watch(sessionProvider).value?.roles ?? const <String>[];
              final isAdmin = roles.contains('ADMIN') || roles.contains('ROLE_ADMIN');
              if (!isAdmin) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: isNarrow ? 8 : 0, top: 4, bottom: 4),
                    child: Text('Admin', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Gerenciar produtos'),
                    subtitle: isNarrow ? null : const Text('Abrir lista de produtos (editar/excluir)'),
                    onTap: () => context.push('/admin/produtos'),
                    dense: isNarrow,
                    contentPadding: tilePadding,
                    minLeadingWidth: minLead,
                  ),
                ],
              );
            }),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          // If not logged in or 401, show a slim state inviting login
          if (!isLoggedIn) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 48),
                    const SizedBox(height: 8),
                    const Text('Você não está logado.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Ir para início'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(child: Text('Erro: $e'));
        },
      ),
    );
  }
}

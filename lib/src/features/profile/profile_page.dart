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
import '../../core/http/api_client.dart';

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
      appBar: AppBar(title: const Text('Perfil')),
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
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

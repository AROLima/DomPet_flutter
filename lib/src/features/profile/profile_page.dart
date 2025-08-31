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

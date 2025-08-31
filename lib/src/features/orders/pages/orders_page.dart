import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/page_result.dart';
import '../orders_service.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus pedidos')),
      body: FutureBuilder<PageResult<Pedido>>(
        future: ref.read(ordersServiceProvider).list(page: _page, size: 10),
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) return Center(child: Text('Erro: ${snap.error}'));
            return const Center(child: CircularProgressIndicator());
          }
          final page = snap.data!;
          if (page.content.isEmpty) return const Center(child: Text('Nenhum pedido'));
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: page.content.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = page.content[i];
                    return ListTile(
                      title: Text('Pedido #${p.id} - ${p.status}'),
                      subtitle: Text('Total: R\$ ' + p.total.toStringAsFixed(2)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/pedidos/${p.id}'),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Página ${page.number + 1} de ${page.totalPages}'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _page > 0 ? () => setState(() => _page -= 1) : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        onPressed: (page.number + 1) < page.totalPages ? () => setState(() => _page += 1) : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

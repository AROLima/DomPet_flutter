// DIDACTIC: OrderDetailPage — order inspection UI
//
// Purpose:
// - Render a single order's details: items, totals, status, and tracking info.
//
// Contract:
// - Inputs: order id.
// - Outputs: display readable order timeline and actions (reorder, contact support).
//
// Notes:
// - Use read-only models and avoid mutating state here; actions that change
//   orders should call OrdersService.

// Order detail page: read-only view of a placed order.
// Contract:
// - Fetches `Pedido` via service and renders delivery info and items.
// - This page is read-only; any customer support actions should live in
//   separate admin flows.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/models/order.dart';
import '../orders_service.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idInt = int.parse(id);
    return Scaffold(
      appBar: AppBar(title: Text('Pedido #$id')),
      body: FutureBuilder<Pedido>(
        future: ref.read(ordersServiceProvider).getById(idInt),
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) return Center(child: Text('Erro: ${snap.error}'));
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Status: ${p.status}', style: Theme.of(context).textTheme.titleMedium),
              Text('Criado em: ${p.createdAt}'),
              const SizedBox(height: 12),
              Text('Endereço de entrega', style: Theme.of(context).textTheme.titleMedium),
              Text('${p.enderecoEntrega.rua}, ${p.enderecoEntrega.numero} - ${p.enderecoEntrega.bairro}'),
              Text('${p.enderecoEntrega.cidade} - CEP ${p.enderecoEntrega.cep}'),
              if (p.enderecoEntrega.complemento != null) Text('Compl.: ${p.enderecoEntrega.complemento}'),
              const Divider(height: 24),
              Text('Itens', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...p.itens.map((it) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(it.nome),
                    subtitle: Text('Qtd: ${it.quantidade} x R\$ ${it.precoUnitario.toStringAsFixed(2)}'),
                    trailing: Text('R\$ ${it.subtotal.toStringAsFixed(2)}'),
                  )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleLarge),
                  Text('R\$ ${p.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

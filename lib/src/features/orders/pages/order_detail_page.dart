// OrderDetailPage — order inspection UI
// Shows status, createdAt, address, items and total of a Pedido.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/models/order.dart';
import '../orders_service.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? idInt = int.tryParse(id);
    if (idInt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedido')),
        body: const Center(child: Text('ID inválido')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #$id'),
        leading: IconButton(
          tooltip: 'Início',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<Pedido>(
        future: ref.read(ordersServiceProvider).getById(idInt),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final p = snapshot.data!;
          final textTheme = Theme.of(context).textTheme;

          String _fmtDate(DateTime dt) {
            final d = dt.toLocal();
            String two(int n) => n < 10 ? '0$n' : '$n';
            return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
          }

          Color _statusColor(String status) {
            final s = status.toUpperCase();
            if (s.contains('PAGO') || s.contains('APROV')) return Colors.green.shade700;
            if (s.contains('CANCEL')) return Colors.red.shade700;
            if (s.contains('ENVIADO') || s.contains('ENTREG')) return Colors.blue.shade700;
            // aguardando/pendente
            return Colors.amber.shade700;
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text('Status:', style: textTheme.titleMedium),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _statusColor(p.status),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        p.status.replaceAll('_', ' '),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Criado em: ${_fmtDate(p.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined),
                              const SizedBox(width: 8),
                              Text('Endereço de entrega', style: textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${p.enderecoEntrega.rua}, ${p.enderecoEntrega.numero} - ${p.enderecoEntrega.bairro}', softWrap: true),
                          Text('${p.enderecoEntrega.cidade} - CEP ${p.enderecoEntrega.cep}', softWrap: true),
                          if (p.enderecoEntrega.complemento != null && p.enderecoEntrega.complemento!.isNotEmpty)
                            Text('Compl.: ${p.enderecoEntrega.complemento}'),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_bag_outlined),
                              const SizedBox(width: 8),
                              Text('Itens', style: textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...p.itens.map((it) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(it.nome, maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 2),
                                          Text('Qtd: ${it.quantidade} x R\$ ${it.precoUnitario.toStringAsFixed(2)}'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('R\$ ${it.subtotal.toStringAsFixed(2)}', textAlign: TextAlign.right),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text('Total', style: textTheme.titleLarge),
                          const Spacer(),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('R\$ ${p.total.toStringAsFixed(2)}', style: textTheme.titleLarge),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

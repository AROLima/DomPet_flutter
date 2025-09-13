// DIDACTIC: OrdersPage — list of user orders
//
// Purpose:
// - Present a paginated list of past orders and allow navigation to details.
//
// Contract:
// - Inputs: authenticated user context and paginated orders provider.
// - Outputs: navigation to `OrderDetailPage`.
//
// Notes:
// - Use `PageResult` parsing helpers provided in shared models for pagination.

// Orders listing page.
// Contract:
// - Fetches pages via `ordersServiceProvider.list` and shows pagination UI.
// - Navigates to order detail via GoRouter on item tap.
// Edge cases:
// - Empty pages are represented as an empty message; network errors show
//   an error message.

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

  String formatDate(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  Color statusColor(BuildContext context, String status) {
    final s = status.toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    if (s.contains('PAGO') || s.contains('APROV')) return Colors.green.shade700;
    if (s.contains('CANCEL')) return Colors.red.shade700;
    if (s.contains('ENVIADO') || s.contains('ENTREG')) return Colors.blue.shade700;
    return scheme.primary; // aguardando/pendente
  }

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
          if (page.content.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.receipt_long_outlined, size: 48),
                    SizedBox(height: 8),
                    Text('Nenhum pedido'),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: page.content.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = page.content[i];
                    final color = statusColor(context, p.status);
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push('/pedidos/${p.id}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.receipt_long_outlined),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Pedido #${p.id}',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(99),
                                            border: Border.all(color: color.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            p.status.replaceAll('_', ' '),
                                            style: TextStyle(color: color, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.schedule, size: 16),
                                            const SizedBox(width: 4),
                                            Text(formatDate(p.createdAt), style: Theme.of(context).textTheme.bodySmall),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LayoutBuilder(builder: (context, c) {
                                      final narrow = c.maxWidth < 360;
                                      final total = 'R\$ ${p.total.toStringAsFixed(2)}';
                                      if (narrow) {
                                        return Text('Total: $total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
                                      }
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Total', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                          FittedBox(
                                            child: Text(total, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Página ${page.number + 1} de ${page.totalPages}'),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Anterior',
                            onPressed: _page > 0 ? () => setState(() => _page -= 1) : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            tooltip: 'Próxima',
                            onPressed: (page.number + 1) < page.totalPages ? () => setState(() => _page += 1) : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

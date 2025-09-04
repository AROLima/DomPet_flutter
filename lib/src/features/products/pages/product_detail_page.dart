// DIDACTIC: ProductDetailPage — product detail and add-to-cart flow
//
// Purpose:
// - Show full product information and allow the user to add items to the cart.
//
// Contract:
// - Inputs: product id or pre-fetched `Produto` instance.
// - Outputs: add-to-cart actions and navigation to related items.
// - Error modes: handle 404s by showing a not-found screen and map server
//   validation errors to user-friendly messages.
//
// Notes:
// - Keep heavy network calls in providers/services; the page should be mostly
//   composition and local UI state.

// Product detail page.
// Contract:
// - Fetches `ProdutoDetalhe` via `productDetailProvider` and displays a
//   responsive layout (row for wide, list for narrow).
// - Action buttons interact with shared `CartController` and show SnackBars.
// Edge cases:
// - UI handles loading/error async states from the provider.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/models/product.dart';
import '../../cart/cart_service.dart';
import '../../cart/local_cart.dart' show MergeConflict;
import '../products_service.dart';
import '../../../../ui/widgets/responsive_scaffold.dart';
import '../../../../ui/design_system.dart';

// Layout switches between a row (wide) and vertical list (narrow) to make good
// use of space on larger screens. Actions such as "Adicionar" call into the
// shared cart controller and show simple SnackBars on success/failure.
class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idInt = int.tryParse(id)!;
    final async = ref.watch(productDetailProvider(idInt));

    return ResponsiveScaffold(
      title: const Text('Produto'),
      body: async.when(
        data: (p) => _Detail(p: p),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.p});
  final ProdutoDetalhe p;
  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  int _qty = 1;
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= AppBreakpoints.md;
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      // Product image
      final image = Semantics(
        label: 'Imagem do produto ${p.nome}',
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            constraints: const BoxConstraints(maxHeight: 420),
            child: Center(
              child: AspectRatio(
                aspectRatio: isWide ? 1 : 4 / 3,
                child: p.imagemUrl != null
                    ? Image.network(
                        p.imagemUrl!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stack) => Container(
                          color: scheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.pets, size: 72),
                        ),
                      )
                    : Container(
                        color: scheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.pets, size: 72),
                      ),
              ),
            ),
          ),
        ),
      );

      // Quantity stepper
      Widget qtyStepper() {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filledTonal(
              tooltip: 'Diminuir',
              onPressed: _qty > 1 ? () => setState(() => _qty -= 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('$_qty', style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton.filledTonal(
              tooltip: 'Aumentar',
              onPressed: () => setState(() => _qty += 1),
              icon: const Icon(Icons.add),
            ),
          ],
        );
      }

      // Info column
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.nome, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                formatBrl(p.preco),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Chip(
                label: Text(p.estoque > 0 ? 'Em estoque' : 'Indisponível'),
                labelStyle: TextStyle(
                  color: p.estoque > 0 ? (isDark ? Colors.white : scheme.onSecondary) : (isDark ? scheme.onErrorContainer : scheme.onSurface),
                  fontWeight: FontWeight.w700,
                ),
                avatar: Icon(
                  p.estoque > 0 ? Icons.check_circle : Icons.schedule,
                  color: p.estoque > 0 ? (isDark ? Colors.white : scheme.onSecondary) : (isDark ? scheme.onErrorContainer : scheme.onSurface),
                ),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                backgroundColor: p.estoque > 0
          ? (isDark ? scheme.secondary.withValues(alpha: 0.6) : scheme.secondary.withValues(alpha: 0.18))
          : (isDark ? scheme.errorContainer.withValues(alpha: 0.6) : scheme.surfaceContainerHighest),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (p.descricao != null)
            Text(
              p.descricao!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              qtyStepper(),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 140, maxWidth: 240),
                child: FilledButton.icon(
                  icon: _adding
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.pets),
                  label: const Text('Adicionar'),
                  onPressed: (p.estoque > 0 && !_adding)
                      ? () async {
                          setState(() => _adding = true);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref.read(cartControllerProvider).addToCart(
                                  produtoId: p.id,
                                  nome: p.nome,
                                  preco: p.preco,
                                  quantidade: _qty,
                                );
                            if (!mounted) return;
                            messenger.showSnackBar(const SnackBar(content: Text('Adicionado ao carrinho')));
                          } on MergeConflict {
                            if (!mounted) return;
                            messenger.showSnackBar(const SnackBar(content: Text('Estoque insuficiente')));
                          } finally {
                            if (mounted) setState(() => _adding = false);
                          }
                        }
                      : null,
                ),
              ),
              if (p.estoque <= 0)
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Avise-me'),
                ),
            ],
          ),
        ],
      );

      // Page content
      final content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: image,
                      ),
                    ),
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 8), child: info)),
                  ],
                )
              : ListView(
                  children: [
                    image,
                    const SizedBox(height: 12),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: info),
                  ],
                ),
        ),
      );

      return content;
    });
  }
}


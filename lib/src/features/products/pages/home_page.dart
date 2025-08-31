import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/product.dart';
import '../../cart/cart_service.dart';
import '../../cart/local_cart.dart' show MergeConflict;
import '../products_service.dart';
import '../../../../ui/widgets/responsive_scaffold.dart';
import '../../../../ui/design_system.dart';
import '../../home/widgets/featured_carousel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchCtrl = TextEditingController();
  String? _categoria;
  int _page = 0;
  Timer? _debouncer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _debouncer?.cancel();
      _debouncer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _page = 0);
      });
    });
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = ProductsQuery(nome: _searchCtrl.text, categoria: _categoria, page: _page, size: 20);
    final pageAsync = ref.watch(productsSearchProvider(q));
    final catsAsync = ref.watch(categoriasProvider);

    return ResponsiveScaffold(
      title: const Text('DomPet'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= AppBreakpoints.md
                ? const FeaturedCarousel()
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar produtos',
                  ),
                  onSubmitted: (_) => setState(() => _page = 0),
                ),
              ),
              const SizedBox(width: 8),
              catsAsync.when(
                data: (cats) => DropdownButton<String?>(
                  value: _categoria,
                  hint: const Text('Categoria'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                    ...cats.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))).toList(),
                  ],
                  onChanged: (v) => setState(() {
                    _categoria = v;
                    _page = 0;
                  }),
                ),
                loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, st) => const Icon(Icons.error_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: pageAsync.when(
              data: (page) => LayoutBuilder(
                builder: (context, constraints) => Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossAxisCountFor(constraints.maxWidth),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          // slightly taller tiles on narrow screens to avoid overflows
                          childAspectRatio: (constraints.maxWidth < AppBreakpoints.md) ? 0.68 : 0.85,
                        ),
                        itemCount: page.content.length,
                        itemBuilder: (_, i) => _ProductCard(
                          produto: page.content[i],
                          isWide: constraints.maxWidth >= AppBreakpoints.md,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: page.number > 0 ? () => setState(() => _page -= 1) : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Página ${page.number + 1} de ${page.totalPages}'),
                        IconButton(
                          onPressed: (page.number + 1) < page.totalPages ? () => setState(() => _page += 1) : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Erro: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({required this.produto, required this.isWide});
  final Produto produto;
  final bool isWide;

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final produto = widget.produto;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: produto.imagemUrl != null
                    ? Image.network(
                        produto.imagemUrl!,
                        fit: BoxFit.contain,
                      )
                    : const Icon(Icons.pets, size: 48),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              produto.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: widget.isWide ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('R\$ ${produto.preco.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (!_loading && produto.estoque > 0)
                        ? () async {
                            setState(() => _loading = true);
                            try {
                              await ref.read(cartControllerProvider).addToCart(
                                    produtoId: produto.id,
                                    nome: produto.nome,
                                    preco: produto.preco,
                                  );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Adicionado ao carrinho')),
                              );
                            } on MergeConflict {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Estoque insuficiente')),
                              );
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          }
                        : null,
                    child: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Adicionar'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => context.push('/produto/${produto.id}'),
                  child: const Text('Ver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

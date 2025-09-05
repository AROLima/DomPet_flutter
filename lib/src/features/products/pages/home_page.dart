// DIDACTIC: Product listing page (HomePage)
//
// Purpose:
// - Provide a searchable, paginated product listing with filtering by
//   category. It coordinates UI controls and providers to render results.
//
// Contract:
// - Inputs: search query, selected category, pagination controls.
// - Outputs: grid of products and navigation to product detail.
// - Behavior: debounces user input (300ms) and parses `q`/`categoria` from
//   the URL on first build to support deep links.
//
// Notes:
// - Keep URL parsing defensive and avoid heavy logic in the widget; delegate
//   data fetching to providers/services.

// Product listing page with search and pagination.
// Contract / behaviors:
// - Debounces search input (300ms) to reduce request churn.
// - Reads query params (`q`, `categoria`) from the URL on first build to
//   support deep-links and preserve state between navigations.
// - Uses providers for paginated search results.
// Edge cases:
// - URL parsing is defensive; fallback to Uri.base when router info is absent.

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
import '../../../shared/widgets/product_image.dart';

// Key behaviors:
// - debounce search input to avoid too many requests
// - parse `q` and `categoria` from the URL on first build so links can
//   pre-fill the state
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
  bool _initFromQuery = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initFromQuery) return;
    try {
      String? loc;
      final r = Router.maybeOf(context);
      if (r?.routeInformationProvider case final p?) {
        final info = p.value;
        loc = info.uri.toString();
      }
      loc ??= Uri.base.toString();
      final uri = Uri.parse(loc);
      final q = uri.queryParameters['q'];
      final cat = uri.queryParameters['categoria'];
      if (q != null && q.isNotEmpty) {
        _searchCtrl.text = q;
      }
      if (cat != null && cat.isNotEmpty) {
        _categoria = cat;
      }
    } catch (_) {}
    _initFromQuery = true;
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
          const FeaturedCarousel(),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 720;
              if (wide) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'O que seu pet precisa?',
      isDense: false,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                      ),
                      onSubmitted: (_) => setState(() => _page = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 260,
                    child: catsAsync.when(
                      data: (cats) => DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: _categoria,
                        decoration: const InputDecoration(
                          isDense: false,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.category_outlined),
                          labelText: 'Categoria',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                          ...cats.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                        ],
                        onChanged: (v) => setState(() {
                          _categoria = v;
                          _page = 0;
                        }),
                      ),
                      loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, st) => const Icon(Icons.error_outline),
                    ),
                  ),
                ]);
              }
              // Narrow: stack vertically
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'O que seu pet precisa?',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                    ),
                    onSubmitted: (_) => setState(() => _page = 0),
                  ),
                  const SizedBox(height: 12),
                  catsAsync.when(
                    data: (cats) => DropdownButtonFormField<String?>(
                      isExpanded: true,
                      value: _categoria,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        prefixIcon: Icon(Icons.category_outlined),
                        labelText: 'Categoria',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                        ...cats.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
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
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: pageAsync.when(
              data: (page) => LayoutBuilder(
                builder: (context, constraints) {
                  final itemsLen = page.content.length;
                  // Choose a pleasant max width for the grid area based on item count
                  final gridMaxWidth = itemsLen <= 1
                      ? 460.0
                      : (itemsLen == 2
                          ? 860.0
                          : 1200.0);
                  final effectiveWidth = constraints.maxWidth.clamp(320.0, gridMaxWidth);
                  // Cap the number of columns to the number of items to avoid large empty space on the right
                  int cols;
                  if (itemsLen <= 1) {
                    cols = 1;
                  } else if (constraints.maxWidth < 720) {
                    cols = itemsLen == 1 ? 1 : 2;
                  } else {
                    cols = gridColsFor(effectiveWidth).clamp(1, itemsLen);
                  }
                  return Column(
                  children: [
                    Expanded(
                      child: page.content.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.search_off, size: 36),
                                  SizedBox(height: 8),
                                  Text('Nenhum produto encontrado'),
                                ],
                              ),
                            )
                          : Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: gridMaxWidth),
                                child: GridView.builder(
                                  padding: EdgeInsets.zero,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    // Center by constraining the width and capping columns to items
                                    crossAxisCount: cols,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                  childAspectRatio: (constraints.maxWidth < AppBreakpoints.xs)
                    ? 0.60
                    : (constraints.maxWidth < AppBreakpoints.md)
                      ? 0.72
                      : 0.86,
                                  ),
                                  itemCount: page.content.length,
                                  itemBuilder: (_, i) => _ProductCard(
                                    produto: page.content[i],
                                    isWide: constraints.maxWidth >= AppBreakpoints.md,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: gridMaxWidth),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: page.number > 0 ? () => setState(() => _page -= 1) : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text('P\u00e1gina ${page.number + 1} de ${page.totalPages}'),
                            IconButton(
                              onPressed: (page.number + 1) < page.totalPages ? () => setState(() => _page += 1) : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
                },
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
  // Remove default theme margin to avoid grid clipping on narrow screens.
  margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reverted to original aspect ratio with explicit contain fit.
            ProductImage(
              url: produto.imagemUrl,
              aspectRatio: 16 / 11,
              fitMode: BoxFit.contain,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.all(6),
              cacheWidth: 520,
              cacheHeight: 520,
              semanticLabel: produto.nome,
              errorIcon: const Icon(Icons.pets),
            ),
            const SizedBox(height: 8),
            Text(
              produto.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: widget.isWide ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(formatBrl(produto.preco)),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (ctx, c) {
              final narrow = c.maxWidth < 180;
              final btnMinSize = const Size(0, 36);
              final pad = const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: btnMinSize, padding: pad),
                      onPressed: (!_loading && produto.estoque > 0)
                          ? () async {
                              setState(() => _loading = true);
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref.read(cartControllerProvider).addToCart(
                                      produtoId: produto.id,
                                      nome: produto.nome,
                                      preco: produto.preco,
                                    );
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Adicionado ao carrinho')),
                                );
                              } on MergeConflict {
                                if (!mounted) return;
                                messenger.showSnackBar(
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
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: btnMinSize, padding: pad),
                      onPressed: () => context.push('/produto/${produto.id}'),
                      child: const Text('Ver'),
                    ),
                  ],
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: btnMinSize, padding: pad),
                    onPressed: (!_loading && produto.estoque > 0)
                        ? () async {
                            setState(() => _loading = true);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ref.read(cartControllerProvider).addToCart(
                                    produtoId: produto.id,
                                    nome: produto.nome,
                                    preco: produto.preco,
                                  );
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Adicionado ao carrinho')),
                              );
                            } on MergeConflict {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Estoque insuficiente')),
                              );
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          }
                        : null,
                    child: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.pets, size: 18),
                              SizedBox(width: 6),
                              Text('Adicionar'),
                            ],
                          ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: btnMinSize, padding: pad),
                      onPressed: () => context.push('/produto/${produto.id}'),
                      child: const Text('Ver'),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

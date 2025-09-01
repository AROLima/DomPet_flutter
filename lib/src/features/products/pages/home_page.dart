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
        loc = info.location;
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
                return Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'O que seu pet precisa?',
                        isDense: false,
                      ),
                      onSubmitted: (_) => setState(() => _page = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 220,
                    child: catsAsync.when(
                      data: (cats) => DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: _categoria,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    ),
                    onSubmitted: (_) => setState(() => _page = 0),
                  ),
                  const SizedBox(height: 8),
                  catsAsync.when(
                    data: (cats) => DropdownButtonFormField<String?>(
                      isExpanded: true,
                      value: _categoria,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        hintText: 'Categoria',
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
                builder: (context, constraints) => Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          // Be more conservative on small widths: use 2 cols below ~720px
                          crossAxisCount: constraints.maxWidth < 720
                              ? 2
                              : gridColsFor(constraints.maxWidth),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
              childAspectRatio: (constraints.maxWidth < AppBreakpoints.xs)
                ? 0.60
                : (constraints.maxWidth < AppBreakpoints.md)
                  ? 0.70
                  : 0.82,
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
                        Text('P\u00e1gina ${page.number + 1} de ${page.totalPages}'),
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
  // Remove default theme margin to avoid grid clipping on narrow screens.
  margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: produto.imagemUrl != null
                    ? Image.network(
                        produto.imagemUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.pets),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.pets),
                      ),
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
            Text(formatBrl(produto.preco)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
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
                    onPressed: () => context.push('/produto/${produto.id}'),
                    child: const Text('Ver'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

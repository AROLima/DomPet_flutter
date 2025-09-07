// DIDACTIC: FeaturedCarousel — resilient homepage carousel
//
// Purpose:
// - Render a carousel of highlighted products using multiple data sources
//   (suggestions -> search -> getAll) with graceful fallbacks.
//
// Contract:
// - Inputs: optional category filter.
// - Output: a responsive carousel widget that exposes navigation and add-to-cart actions.
// - Behavior: autoplay when multiple items; pauses on user interaction.
//
// Notes:
// - Designed for resilience: it tries several endpoints and falls back to
//   avoid empty UI sections on transient backend failures.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/widgets/product_image.dart';
import 'package:go_router/go_router.dart';
import '../../cart/cart_service.dart';
import '../../cart/local_cart.dart' show MergeConflict;
import '../../products/products_service.dart';
import '../../../shared/models/product.dart';
import '../../../../ui/design_system.dart';

// Featured carousel used on the home page.
// It tries a few data sources in order: suggestions -> search -> getAll, and
// uses the first non-empty result. Autoplay is enabled when there is more than
// one item and pauses while the user interacts (scroll start/end).
class FeaturedCarousel extends ConsumerStatefulWidget {
  const FeaturedCarousel({super.key, this.category});
  final String? category;

  @override
  ConsumerState<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<FeaturedCarousel> {
  late PageController _controller;
  double _viewport = 0.92;
  int _index = 0;
  Timer? _auto;
  Timer? _unpause;
  int _count = 0;
  bool _paused = false;
  Future<List<Produto>>? _future;

  @override
  void dispose() {
    _auto?.cancel();
  _unpause?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAuto() {
    _auto?.cancel();
    if (_count <= 1) return;
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _paused || !_controller.hasClients || _count <= 1) return;
      final next = (_index + 1) % _count;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 360), curve: Curves.easeOut);
    });
  }

  @override
  void initState() {
    super.initState();
  _controller = PageController(viewportFraction: _viewport, keepPage: true);
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant FeaturedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _index = 0;
      _future = _load();
      _restartAuto();
      setState(() {});
    }
  }

  Future<List<Produto>> _load() async {
    final service = ref.read(productsServiceProvider);
    // 1) Try suggestions endpoint
    try {
      final sugs = await service.suggestions('', limit: 8);
      // If suggestions exist, try to merge with search results to get images/prices
      final ids = sugs.map((e) => e.id).toSet();
      if (ids.isNotEmpty) {
    final page = await service.search(page: 0, size: 12, categoria: widget.category);
        final merged = <int, Produto>{};
        for (final p in page.content) {
          if (ids.contains(p.id)) merged[p.id] = p;
        }
        final list = merged.values.toList();
        if (list.length >= 2) return list;
      }
    } catch (_) {}

    // 2) Fallback: first page of search
    try {
  final page = await service.search(page: 0, size: 8, categoria: widget.category);
      if (page.content.isNotEmpty) {
        // distinct by id
        final seen = <int>{};
        final distinct = <Produto>[];
        for (final p in page.content) {
          if (seen.add(p.id)) distinct.add(p);
        }
        if (distinct.length >= 2) return distinct;
      }
    } catch (_) {}

    // 3) Last fallback: getAll (up to 8 items)
    try {
      final all = await service.getAll();
      final list = all.take(8).toList();
      if (list.length >= 2) return list;
    } catch (_) {
      // ignore
    }

    // 4) Ensure carousel has at least 2 slides: duplicate single item if needed
    try {
      final page = await service.search(page: 0, size: 2, categoria: widget.category);
      final items = page.content.take(2).toList();
      if (items.length == 1) return [items.first, items.first];
      if (items.length >= 2) return items;
    } catch (_) {}

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Produto>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          // simple shimmer placeholder
          return _ShimmerBox(height: 220);
        }
        if (snap.hasError) {
          return _ShimmerBox(height: 220);
        }
  final items = snap.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth.clamp(320.0, 1920.0);
          final aspect = heroAspectFor(w);
          // On very narrow viewports, use a fuller fraction to give more width per slide
          final targetVf = constraints.maxWidth < 380 ? 0.98 : 0.92;
          // Keep controller stable to avoid runtime glitches; ignore minor viewport changes.
          _viewport = targetVf;
          final hasMultiple = items.length > 1;
          // Ensure current index is valid for the current item count
          final desiredIndex = items.isEmpty ? 0 : _index.clamp(0, items.length - 1);
          if (desiredIndex != _index) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _index = desiredIndex;
              if (_controller.hasClients) {
                try { _controller.jumpToPage(_index); } catch (_) {}
              }
              setState(() {});
            });
          }
          // Update autoplay source count and restart if it changed
          if (_count != items.length) {
            _count = items.length;
            _restartAuto();
          }
          final dotIndex = _index.clamp(0, items.length - 1);
          return Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400, maxHeight: 420),
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n is ScrollStartNotification) {
                              _paused = true;
                              _unpause?.cancel();
                              // Fallback: ensure autoplay resumes even if End isn't delivered
                              _unpause = Timer(const Duration(milliseconds: 1200), () {
                                if (mounted) setState(() => _paused = false);
                              });
                            } else if (n is ScrollEndNotification) {
                              _unpause?.cancel();
                              _paused = false;
                            }
                            return false;
                          },
                          child: ScrollConfiguration(
                            behavior: const MaterialScrollBehavior().copyWith(
                              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                            ),
                            child: PageView.builder(
                              controller: _controller,
                              physics: const PageScrollPhysics(),
                              onPageChanged: (i) => setState(() => _index = i),
                              itemCount: items.length,
                              itemBuilder: (ctx, i) {
                                final p = items[i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: _SlideCard(key: ValueKey('feat_${p.id}'), product: p),
                                );
                              },
                            ),
                          ),
                        ),
                        if (hasMultiple)
                          Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton.filledTonal(
                              tooltip: 'Anterior',
                              onPressed: () {
                                if (!_controller.hasClients || items.isEmpty) return;
                                final prev = (_index - 1) < 0 ? items.length - 1 : _index - 1;
                                try {
                                  _controller.animateToPage(prev, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.chevron_left),
                            ),
                          ),
                        ),
                        if (hasMultiple)
                          Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton.filledTonal(
                              tooltip: 'Próximo',
                              onPressed: () {
                                if (!_controller.hasClients || items.isEmpty) return;
                                final next = (_index + 1) % items.length;
                                try {
                                  _controller.animateToPage(next, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (hasMultiple) _Dots(count: items.length, index: dotIndex, controller: _controller),
            ],
          );
        });
      },
    );
  }
}

class _SlideCard extends ConsumerWidget {
  const _SlideCard({super.key, required this.product});
  final Produto product;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: 'Destaque: ${product.nome}',
      button: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
        fit: StackFit.expand,
        children: [
          // imagem responsiva
          if (product.imagemUrl != null)
            ProductImage(
              url: product.imagemUrl,
              cacheWidth: 1600,
              // Remover cacheHeight para não influenciar proporção do decoder
              aspectRatio: null, // preenche o pai
              padding: EdgeInsets.zero, // sem bordas aparentes
              fitMode: BoxFit.cover, // garante cobertura sem distorcer
              borderRadius: BorderRadius.circular(18),
              errorIcon: const Icon(Icons.pets, size: 72),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x220F766E), Color(0x00000000)],
                ),
              ),
            ),
          // gradiente para legibilidade
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Color(0xB3000000), Color(0x00000000)],
              ),
            ),
          ),
          // conteúdo
          LayoutBuilder(builder: (context, c) {
            final tiny = c.maxWidth < 380;
            final pad = tiny ? const EdgeInsets.all(12) : const EdgeInsets.all(20);
            final titleStyle = (Theme.of(context).textTheme.headlineSmall ?? const TextStyle()).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: tiny ? 18 : null,
            );
            return Padding(
              padding: pad,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: tiny ? 360 : 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 120, maxWidth: tiny ? 160 : 220),
                            child: FilledButton(
                              style: tiny
                                  ? FilledButton.styleFrom(minimumSize: const Size(100, 36), padding: const EdgeInsets.symmetric(horizontal: 12))
                                  : null,
                              onPressed: () => context.push('/produto/${product.id}'),
                              child: const Text('Ver produto'),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(minWidth: 120, maxWidth: tiny ? 160 : 220),
                            child: OutlinedButton(
                              style: tiny
                                  ? OutlinedButton.styleFrom(minimumSize: const Size(100, 36), padding: const EdgeInsets.symmetric(horizontal: 12))
                                  : null,
                              onPressed: () async {
                                try {
                                  await ref.read(cartControllerProvider).addToCart(
                                        produtoId: product.id,
                                        nome: product.nome,
                                        preco: product.preco,
                                      );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicionado ao carrinho')));
                                } on MergeConflict {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estoque insuficiente')));
                                }
                              },
                              child: const Text('Adicionar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.height});
  final double height;
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppTokens.slow)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.6, end: 1.0).animate(_controller),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTokens.r12),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.controller});
  final int count;
  final int index;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: List.generate(count, (i) {
        final active = i == index;
        return InkWell(
          onTap: () => controller.animateToPage(
            i,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
          ),
          borderRadius: BorderRadius.circular(99),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 18 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade500,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

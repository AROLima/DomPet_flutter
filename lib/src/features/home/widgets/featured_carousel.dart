import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../products/products_service.dart';
import '../../../shared/models/product.dart';
import '../../../../ui/design_system.dart';

class FeaturedCarousel extends ConsumerStatefulWidget {
  const FeaturedCarousel({super.key});

  @override
  ConsumerState<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends ConsumerState<FeaturedCarousel> {
  final _controller = PageController(viewportFraction: 0.95);
  int _index = 0;

  Future<List<Produto>> _load() async {
    final service = ref.read(productsServiceProvider);
    // Try destaque (fallback to first page of search)
    try {
      final res = await service.search(nome: null, categoria: null, page: 0, size: 8);
      return res.content;
    } catch (_) {
      // Try suggestions empty query
      try {
        final sugs = await service.suggestions('');
        // We only have id & nome; fallback price/stock omitted
        return sugs.map((s) => Produto(id: s.id, nome: s.nome, preco: 0, estoque: 0, ativo: true)).toList();
      } catch (_) {
        // Last fallback: getAll
        try {
          final all = await service.getAll();
          return all.take(8).toList();
        } catch (_) {
          return [];
        }
      }
    }
  }

  double _aspectFor(double width) {
    if (width < AppBreakpoints.xs) return 4 / 3;
    if (width < AppBreakpoints.sm) return 4 / 3;
    if (width < AppBreakpoints.md) return 16 / 9;
    return 16 / 6; // lg/xl
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Produto>>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          // simple shimmer placeholder
          return _ShimmerBox(height: 220);
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final aspect = _aspectFor(width);
          return Column(
            children: [
              SizedBox(
                height: (constraints.maxWidth * (1 / aspect)).clamp(160.0, 360.0),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: items.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _FeaturedSlide(item: items[i]),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (int i = 0; i < items.length; i++)
                    AnimatedContainer(
                      duration: AppTokens.fast,
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                      ),
                    ),
                ],
              ),
            ],
          );
        });
      },
    );
  }
}

class _FeaturedSlide extends StatelessWidget {
  const _FeaturedSlide({required this.item});
  final Produto item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Destaque: ${item.nome}',
      button: true,
      child: Focus(
        child: InkWell(
          onTap: () => context.push('/produto/${item.id}'),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imagemUrl != null)
                    Image.network(
                      item.imagemUrl!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary.withOpacity(0.15), Colors.transparent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTokens.r12),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.r12),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nome,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.preco > 0 ? 'R\$ ${item.preco.toStringAsFixed(2)}' : '',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 120),
                            child: FilledButton(
                              onPressed: () => context.push('/produto/${item.id}'),
                              child: const Text('Ver produto'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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

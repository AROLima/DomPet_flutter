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
import 'dart:ui';
import 'package:palette_generator/palette_generator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/models/product.dart';
import '../../cart/cart_service.dart';
import '../../cart/local_cart.dart' show MergeConflict;
import '../products_service.dart';
import '../../../../ui/widgets/responsive_scaffold.dart';
import '../../../../ui/widgets/home_app_drawer.dart';
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
      drawer: const HomeAppDrawer(),
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
          child: LayoutBuilder(
            builder: (context, imgConstraints) {
              return Container(
                constraints: const BoxConstraints(maxHeight: 420),
                decoration: const BoxDecoration(color: AppColors.neutralContainer),
                child: AspectRatio(
                  aspectRatio: isWide ? 1 : 4 / 3,
                  child: p.imagemUrl == null
                      ? Container(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          alignment: Alignment.center,
                          child: const Icon(Icons.pets, size: 72),
                        )
                      : _BlurFillNetworkImage(url: p.imagemUrl!),
                ),
              );
            },
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

// Small reusable widget: loads an image once and paints a blurred, darkened
// stretched background version behind the sharp foreground to avoid empty bars.
class _BlurFillNetworkImage extends StatefulWidget {
  const _BlurFillNetworkImage({required this.url});
  final String url;
  @override
  State<_BlurFillNetworkImage> createState() => _BlurFillNetworkImageState();
}

class _BlurFillNetworkImageState extends State<_BlurFillNetworkImage> {
  static final Map<String, PaletteGenerator> _cache = {};
  PaletteGenerator? _palette;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _extract();
  }

  Future<void> _extract() async {
    if (_cache.containsKey(widget.url)) {
      _palette = _cache[widget.url];
      return; // Let build pick it up synchronously
    }
    setState(() => _loading = true);
    try {
      final pg = await PaletteGenerator.fromImageProvider(
        NetworkImage(widget.url),
        size: const Size(80, 80), // small sample for speed
        maximumColorCount: 12,
      );
      _cache[widget.url] = pg;
      if (mounted) setState(() => _palette = pg);
    } catch (_) {
      // ignore errors (keep default)
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dominant = _palette?.dominantColor?.color;
    final vibrant = _palette?.vibrantColor?.color;
    final baseColor = dominant ?? vibrant ?? scheme.secondary.withValues(alpha: 0.5);
    // Derive lighter & darker variants
    Color overlayHigh = baseColor.withValues(alpha: 0.28);
    Color overlayLow = baseColor.withValues(alpha: 0.06);
    if (Theme.of(context).brightness == Brightness.dark) {
      overlayHigh = baseColor.withValues(alpha: 0.40);
      overlayLow = baseColor.withValues(alpha: 0.12);
    }

    return _HoverScale(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.network(
              widget.url,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              color: scheme.surface.withValues(alpha: 0.05),
              colorBlendMode: BlendMode.srcOver,
            ),
          ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: AnimatedContainer(
                  duration: AppTokens.normal,
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [overlayHigh, overlayLow],
                    ),
                  ),
                ),
              ),
            ),
          if (_loading) const Center(child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2))),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _ShimmerNetworkImage(url: widget.url),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple hover scale wrapper (desktop/web). Mobile: no change.
class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child});
  final Widget child;
  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.015 : 1,
        duration: AppTokens.normal,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// Shimmer while image loads (no extra package): animated gradient sweep.
class _ShimmerNetworkImage extends StatefulWidget {
  const _ShimmerNetworkImage({required this.url});
  final String url;
  @override
  State<_ShimmerNetworkImage> createState() => _ShimmerNetworkImageState();
}

class _ShimmerNetworkImageState extends State<_ShimmerNetworkImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.url,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSync) {
        if (frame != null) return child; // finished
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return CustomPaint(
              painter: _ShimmerPainter(progress: _c.value),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                child: const Icon(Icons.pets, size: 56, color: Colors.white54),
              ),
            );
          },
        );
      },
      errorBuilder: (context, error, stack) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.pets, size: 72),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
  final base = Paint()..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawRect(Offset.zero & size, base);
    final gradientWidth = size.width * 0.45;
    final dx = (size.width + gradientWidth) * progress - gradientWidth;
    final rect = Rect.fromLTWH(dx, 0, gradientWidth, size.height);
    final gradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.00),
        Colors.white.withValues(alpha: 0.25),
        Colors.white.withValues(alpha: 0.00),
      ],
      stops: const [0, 0.5, 1],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.progress != progress;
}


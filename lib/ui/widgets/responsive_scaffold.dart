import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../design_system.dart';
import '../../src/features/cart/cart_service.dart';
import 'app_drawer.dart';

class ResponsiveScaffold extends ConsumerWidget {
  /// Scaffold responsivo que adapta drawer/performance de layout com base em breakpoints.
  ///
  /// Dicas de estudo:
  /// - Se a largura for >= md, exibimos o drawer permanentemente (desktop-like).
  /// - A widget `_CartButton` observa o provider `cartCountProvider` e exibe badge condicionalmente.
  const ResponsiveScaffold({super.key, required this.body, this.title, this.actions, this.fab, this.drawer});
  final Widget body;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? fab;
  final Widget? drawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
  final padding = appPaddingFor(width);
  final logoSize = width >= AppBreakpoints.md ? 32.0 : 24.0;

  final isMD = width >= AppBreakpoints.md;
      return Scaffold(
        appBar: AppBar(
          // Don't override leading so the default hamburger shows on small screens
          // Place a small logo inside the title instead
    title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset(
                  'web/icons/Icon-192.png',
                  width: logoSize,
                  height: logoSize,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.pets, size: logoSize),
                ),
              ),
              Flexible(child: title ?? const Text('DomPet')),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Perfil',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/perfil'),
            ),
            _CartButton(),
            ...?actions,
          ],
        ),
  // Show modal drawer on small screens; show permanent drawer from md+
  drawer: width < AppBreakpoints.md ? (drawer ?? const AppDrawer()) : null,
        floatingActionButton: fab,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      if (isMD)
              SizedBox(
                width: 280,
        child: drawer ?? const AppDrawer(),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: padding,
                    child: body,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CartButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends ConsumerState<_CartButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppTokens.fast, lowerBound: 0.95, upperBound: 1.0)..value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(cartCountProvider);
    return countAsync.when(
      data: (qty) {
        return ScaleTransition(
          scale: _controller,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => context.push('/cart'),
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Carrinho',
              ),
              if (qty > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$qty', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => IconButton(
        onPressed: () => context.push('/cart'),
        icon: const Icon(Icons.shopping_cart_outlined),
        tooltip: 'Carrinho',
      ),
      error: (e, st) => IconButton(
        onPressed: () => context.push('/cart'),
        icon: const Icon(Icons.shopping_cart_outlined),
        tooltip: 'Carrinho',
      ),
    );
  }
}

// Drawer moved to AppDrawer for reuse

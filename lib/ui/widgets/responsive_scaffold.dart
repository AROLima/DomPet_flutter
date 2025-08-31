import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../design_system.dart';
import '../../src/features/cart/cart_service.dart';

class ResponsiveScaffold extends ConsumerWidget {
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

      return Scaffold(
        appBar: AppBar(
          title: title ?? const Text('DomPet'),
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
        drawer: width < AppBreakpoints.xs ? (drawer ?? const _DefaultDrawer()) : null,
        floatingActionButton: fab,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: padding,
              child: body,
            ),
          ),
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

class _DefaultDrawer extends StatelessWidget {
  const _DefaultDrawer();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('DomPet')),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Início'),
            onTap: () => context.go('/'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil'),
            onTap: () => context.go('/perfil'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Carrinho'),
            onTap: () => context.go('/cart'),
          ),
        ],
      ),
    );
  }
}

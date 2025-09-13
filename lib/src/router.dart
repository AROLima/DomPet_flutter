// DIDACTIC: Router and route guards for the application.
//
// Purpose (short):
// - Centralizes named routes and navigation rules used by the whole app.
// - Keeps route protection logic (redirects) declarative and reactive by
//   listening to `sessionProvider` so login/logout immediately affect routing.
//
// Contract / responsibilities:
// - Input: navigation events and current Session (via Riverpod).
// - Output: GoRouter configuration that maps paths to builders and redirects.
// - Error modes: invalid/missing session -> redirect to '/login';
//   unauthorized role -> redirect to '/'.
//
// Notes for readers:
// - Keep this file thin: complex auth or feature logic belongs to services.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/auth/session.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/products/pages/home_page.dart';
import 'features/home/home_shell.dart';
import 'features/products/pages/product_detail_page.dart';
import 'features/cart/pages/cart_page.dart';
import 'features/orders/pages/checkout_page.dart';
import 'features/orders/pages/orders_page.dart';
import 'features/orders/pages/order_detail_page.dart';
import 'features/profile/profile_page.dart';
import 'shared/splash_page.dart';
import '../features/admin/products/admin_produto_form_page.dart';
import '../features/admin/products/admin_produtos_page.dart';
import '../features/admin/products/admin_produto_delete_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
  // The router listens to this notifier so it can re-evaluate redirects
  // when the session changes (login/logout). This keeps route protection
  // reactive without tightly coupling the router to session internals.
  refreshListenable: ref.watch(_routerRefreshProvider),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/produtos',
        name: 'produtos',
  builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/produto/:id',
        name: 'produto',
        builder: (context, state) => ProductDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartPage(),
        redirect: (context, state) {
          return null; // cart acessível antes do login (local)
        },
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutPage(),
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          if (session == null) return '/login';
          return null;
        },
      ),
      GoRoute(
        path: '/pedidos',
        name: 'orders',
        builder: (context, state) => const OrdersPage(),
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          if (session == null) return '/login';
          return null;
        },
      ),
      GoRoute(
        path: '/pedidos/:id',
        name: 'orderDetail',
        builder: (context, state) => OrderDetailPage(id: state.pathParameters['id']!),
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          if (session == null) return '/login';
          return null;
        },
      ),
      GoRoute(
        path: '/perfil',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          if (session == null) return '/login';
          return null;
        },
      ),
      // Admin: produtos
      GoRoute(
        path: '/admin/produtos',
        name: 'adminProdutos',
        builder: (context, state) => const AdminProdutosPage(),
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          final roles = session == null ? const <String>[] : session.roles;
          if (session == null) return '/login';
          if (!(roles.contains('ADMIN') || roles.contains('ROLE_ADMIN'))) return '/?denied=1';
          return null;
        },
      ),
      GoRoute(
        path: '/admin/produtos/novo',
        name: 'adminProdutosNovo',
        builder: (context, state) => const AdminProdutoFormPage(),
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          final roles = session == null ? const <String>[] : session.roles;
          if (session == null) return '/login';
          if (!(roles.contains('ADMIN') || roles.contains('ROLE_ADMIN'))) return '/?denied=1';
          return null;
        },
      ),
      GoRoute(
        path: '/admin/produtos/:id/editar',
        name: 'adminProdutosEditar',
        builder: (context, state) => AdminProdutoFormPage(editarId: int.tryParse(state.pathParameters['id'] ?? '')), 
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          final roles = session == null ? const <String>[] : session.roles;
          if (session == null) return '/login';
          if (!(roles.contains('ADMIN') || roles.contains('ROLE_ADMIN'))) return '/?denied=1';
          return null;
        },
      ),
      GoRoute(
        path: '/admin/produtos/:id/excluir',
        name: 'adminProdutosExcluir',
        builder: (context, state) => AdminProdutoDeletePage(id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
        redirect: (context, state) {
          final session = ref.read(sessionProvider).value;
          final roles = session == null ? const <String>[] : session.roles;
          if (session == null) return '/login';
          if (!(roles.contains('ADMIN') || roles.contains('ROLE_ADMIN'))) return '/?denied=1';
          return null;
        },
      ),
    ],
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      if (isSplash) return null;
      final session = ref.read(sessionProvider).value;
      final loc = state.matchedLocation;
      final bool protected = loc.startsWith('/checkout') || loc.startsWith('/pedidos');
      if (protected && session == null) return '/login';
      return null;
    },
  );

  // Listener adicional: se sessão cair para null estando em rota protegida, força login
  ref.listen(sessionProvider, (prev, next) {
    final was = prev?.value; // prev pode ser null na primeira chamada
    final now = next.value;
    if (was != null && now == null) {
      final currentLoc = router.routerDelegate.currentConfiguration.uri.toString();
      final isPublic = currentLoc.startsWith('/login') || currentLoc.startsWith('/register') || currentLoc.startsWith('/produtos') || currentLoc == '/' || currentLoc.startsWith('/produto/');
      if (!isPublic) {
        // Evita empilhar múltiplos redirects se já está indo ao login
        router.go('/login');
      }
    }
  });

  return router;
});

final _routerRefreshProvider = Provider<ChangeNotifier>((ref) {
  final notifier = _GoRouterRefreshNotifier();
  ref.listen(sessionProvider, (previous, next) {
    notifier.notify();
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

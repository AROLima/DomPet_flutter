import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/auth/session.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/products/pages/home_page.dart';
import 'features/products/pages/product_detail_page.dart';
import 'features/cart/pages/cart_page.dart';
import 'features/orders/pages/checkout_page.dart';
import 'features/orders/pages/orders_page.dart';
import 'features/orders/pages/order_detail_page.dart';
import 'features/profile/profile_page.dart';
import 'shared/splash_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
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
    ],
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/splash';
      if (isSplash) return null;
      final session = ref.read(sessionProvider).value;
      final loc = state.matchedLocation;
      bool protected = loc.startsWith('/checkout') || loc.startsWith('/pedidos');
      if (protected && session == null) return '/login';
      return null;
    },
  );
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

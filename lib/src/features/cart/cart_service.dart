import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/http/api_client.dart';
import '../../core/auth/session.dart';
import '../../shared/models/cart.dart';
import 'local_cart.dart';

final cartServiceProvider = Provider<CartService>((ref) => RemoteCartService(ref));
// Tick used to notify listeners to refetch cart data after mutations
final cartRefreshTickProvider = StateProvider<int>((ref) => 0);
// Optimistic delta added to the computed cart count (e.g., while a remote add is in-flight)
final cartOptimisticDeltaProvider = StateProvider<int>((ref) => 0);

// Expose a computed badge count provider (sum of quantities)
final cartCountProvider = FutureProvider<int>((ref) async {
  // Depend on tick and optimistic delta for recomputation
  ref.watch(cartRefreshTickProvider);
  final optimistic = ref.watch(cartOptimisticDeltaProvider);
  final controller = ref.read(cartControllerProvider);
  try {
    final cart = await controller.fetchCart();
    final base = cart.itens.fold<int>(0, (p, e) => p + e.quantidade);
    return base + optimistic;
  } catch (_) {
    return optimistic; // network error: show at least the optimistic value
  }
});

class RemoteCartService implements CartService {
  RemoteCartService(this.ref);
  final Ref ref;
  Dio get _dio => ref.read(dioProvider);

  @override
  Future<Carrinho> getCart() async {
    final res = await _dio.get('/cart');
    return Carrinho.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<Carrinho> addItem({required int produtoId, required int quantidade}) async {
    try {
      final res = await _dio.post('/cart/items', data: {
        'produtoId': produtoId,
        'quantidade': quantidade,
      });
      return Carrinho.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw MergeConflict();
      }
      rethrow;
    }
  }

  @override
  Future<Carrinho> updateItem({required int itemId, required int quantidade}) async {
    final res = await _dio.patch('/cart/items/$itemId', data: {
      'quantidade': quantidade,
    });
    return Carrinho.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<Carrinho> removeItem(int itemId) async {
    final res = await _dio.delete('/cart/items/$itemId');
    if (res.statusCode == 204 || res.data == null || (res.data is String && (res.data as String).isEmpty)) {
      // Backend returns no content for delete; fetch the updated cart
      return getCart();
    }
    if (res.statusCode == 404) {
      // Item not found remotely; treat as removed and get fresh cart
      return getCart();
    }
    return Carrinho.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> clear() async {
    try {
      await _dio.delete('/cart');
    } on DioException catch (e) {
      // Fallback: endpoint não existe; remove item a item
      if (e.response?.statusCode == 404 || e.type == DioExceptionType.unknown) {
        try {
          final cart = await getCart();
          for (final item in cart.itens) {
            try {
              await _dio.delete('/cart/items/${item.itemId}');
            } catch (_) {}
          }
        } catch (_) {}
      } else {
        rethrow;
      }
    }
  }
}

/// Controla operações considerando sessão: local antes do login, remoto após login.
final cartControllerProvider = Provider<CartController>((ref) => CartController(ref));

class CartController {
  CartController(this.ref);
  final Ref ref;

  Future<bool> get _isLoggedIn async => (await ref.read(sessionProvider.future)) != null;

  Future<Carrinho> fetchCart() async {
    const localEmpty = Carrinho(itens: [], total: 0);
    if (await _isLoggedIn) {
      try {
        return await ref.read(cartServiceProvider).getCart();
      } on DioException catch (e) {
        // Token inválido/expirado após restart do backend → limpa sessão e usa carrinho local
        if (e.response?.statusCode == 401) {
          await ref.read(sessionProvider.notifier).clear();
          final local = await ref.read(localCartProvider.future);
          return local.getCart();
        }
        rethrow;
      } catch (_) {
        // Falha de rede: mostra carrinho local para não quebrar a tela
        final local = await ref.read(localCartProvider.future);
        return local.getCart();
      }
    }
    return ref.read(localCartProvider).maybeWhen(
          data: (l) => l.getCart(),
          orElse: () async => localEmpty,
        );
  }

  Future<void> addToCart({required int produtoId, required String nome, required double preco, int quantidade = 1}) async {
    if (await _isLoggedIn) {
      // optimistic increment
      ref.read(cartOptimisticDeltaProvider.notifier).state += quantidade;
      try {
        await ref.read(cartServiceProvider).addItem(produtoId: produtoId, quantidade: quantidade);
      } on MergeConflict {
        // revert optimistic inc on conflict
        ref.read(cartOptimisticDeltaProvider.notifier).state -= quantidade;
        rethrow;
      } finally {
        // trigger badge/cart refresh and clear optimistic bump after success
        ref.read(cartRefreshTickProvider.notifier).state++;
        // allow optimistic to settle back to 0 once remote update reflects
        ref.read(cartOptimisticDeltaProvider.notifier).state = 0;
      }
    } else {
      final local = await ref.read(localCartProvider.future);
      await local.addItem(produtoId: produtoId, nome: nome, preco: preco, quantidade: quantidade);
      ref.read(cartRefreshTickProvider.notifier).state++;
    }
  }

  Future<void> updateQty({required int produtoId, required int? itemId, required int quantidade, required double preco, required String nome}) async {
    if (await _isLoggedIn) {
      if (itemId == null) return; // remoto sempre tem itemId
      await ref.read(cartServiceProvider).updateItem(itemId: itemId, quantidade: quantidade);
      ref.read(cartRefreshTickProvider.notifier).state++;
    } else {
      final local = await ref.read(localCartProvider.future);
      await local.updateQty(produtoId: produtoId, quantidade: quantidade);
      ref.read(cartRefreshTickProvider.notifier).state++;
    }
  }

  Future<void> remove({required int produtoId, int? itemId}) async {
    if (await _isLoggedIn) {
      if (itemId == null) return;
      await ref.read(cartServiceProvider).removeItem(itemId);
      ref.read(cartRefreshTickProvider.notifier).state++;
    } else {
      final local = await ref.read(localCartProvider.future);
      await local.removeItem(produtoId);
      ref.read(cartRefreshTickProvider.notifier).state++;
    }
  }

  Future<void> clear() async {
    if (await _isLoggedIn) {
      await ref.read(cartServiceProvider).clear();
      ref.read(cartRefreshTickProvider.notifier).state++;
    } else {
      final local = await ref.read(localCartProvider.future);
      await local.clear();
      ref.read(cartRefreshTickProvider.notifier).state++;
    }
  }
}

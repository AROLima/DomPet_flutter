import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/cart.dart';
import '../products/products_service.dart';

// DIDACTIC: LocalCart — ephemeral local cart persistence and delta model
//
// Purpose:
// - Store local cart deltas and provide merge helpers for syncing with remote
//   cart on login/checkout.
//
// Contract:
// - Inputs: add/remove delta operations, local-only negative IDs for new items.
// - Outputs: a compact change-set used to reconcile with server state.
// - Error modes: merge conflicts surfaced as `MergeConflict` for higher layers.
//
// Notes:
// - Keep storage small (SharedPreferences / small store) and avoid duplicating
//   authoritative cart logic found on the server.

// Local cart implementation stored in SharedPreferences. This is used while the
// user is anonymous. On login the app attempts to merge local items into the
// remote cart using `mergeIntoRemote`, handling 409 conflicts by checking the
// latest stock and adjusting quantities where possible.
final localCartProvider = FutureProvider<LocalCart>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return LocalCart(ref, prefs);
});

class LocalCart {
  LocalCart(this.ref, this._prefs);
  final Ref ref;
  final SharedPreferences _prefs;
  static const _key = 'local_cart_v1';

  Carrinho _get() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const Carrinho(itens: [], total: 0);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return Carrinho.fromJson(map);
  }

  Future<void> _set(Carrinho c) async {
    await _prefs.setString(_key, jsonEncode(c.toJson()));
  }

  Future<Carrinho> getCart() async => _get();

  Future<void> addItem({required int produtoId, required String nome, required double preco, int quantidade = 1}) async {
    final cart = _get();
    final itens = [...cart.itens];
    final idx = itens.indexWhere((e) => e.produtoId == produtoId);
    if (idx >= 0) {
      final cur = itens[idx];
      final q = cur.quantidade + quantidade;
      itens[idx] = cur.copyWith(quantidade: q, subtotal: q * cur.precoUnitario);
    } else {
      itens.add(ItemCarrinho(
        itemId: -DateTime.now().millisecondsSinceEpoch, // local only
        produtoId: produtoId,
        nome: nome,
        precoUnitario: preco,
        quantidade: quantidade,
        subtotal: quantidade * preco,
      ));
    }
    final total = itens.fold<double>(0, (p, e) => p + e.subtotal);
    await _set(Carrinho(itens: itens, total: total));
  }

  Future<void> updateQty({required int produtoId, required int quantidade}) async {
    final cart = _get();
    final itens = [...cart.itens];
    final idx = itens.indexWhere((e) => e.produtoId == produtoId);
    if (idx >= 0) {
      final cur = itens[idx];
      if (quantidade <= 0) {
        itens.removeAt(idx);
      } else {
        itens[idx] = cur.copyWith(quantidade: quantidade, subtotal: quantidade * cur.precoUnitario);
      }
      final total = itens.fold<double>(0, (p, e) => p + e.subtotal);
      await _set(Carrinho(itens: itens, total: total));
    }
  }

  Future<void> removeItem(int produtoId) async {
    final cart = _get();
    final itens = cart.itens.where((e) => e.produtoId != produtoId).toList();
    final total = itens.fold<double>(0, (p, e) => p + e.subtotal);
    await _set(Carrinho(itens: itens, total: total));
  }

  Future<void> clear() async => _prefs.remove(_key);

  /// Merge: GET /cart, POST each local item; on 409, fetch stock and adjust qty.
  Future<void> mergeIntoRemote(CartService remote) async {
    final local = _get();
    if (local.itens.isEmpty) return;
    await remote.getCart();
    for (final item in local.itens) {
      try {
        await remote.addItem(produtoId: item.produtoId, quantidade: item.quantidade);
  } on MergeConflict {
        // try to adjust based on live stock
        final estoque = await _getEstoque(item.produtoId);
        final novaQtd = estoque > 0 ? (item.quantidade > estoque ? estoque : item.quantidade) : 0;
        if (novaQtd > 0) {
          await remote.addItem(produtoId: item.produtoId, quantidade: novaQtd);
        }
        // an optional UI notification channel could be used here to inform
        // the user about quantity adjustments.
      }
    }
    await clear();
  }

  Future<int> _getEstoque(int produtoId) async {
    try {
      final p = await ref.read(productsServiceProvider).getDetail(produtoId);
      return p.estoque;
    } catch (_) {
      return 0;
    }
  }
}

abstract class CartService {
  Future<Carrinho> getCart();
  Future<Carrinho> addItem({required int produtoId, required int quantidade});
  Future<Carrinho> updateItem({required int itemId, required int quantidade});
  Future<Carrinho> removeItem(int itemId);
  Future<void> clear();
}

class MergeConflict implements Exception {}


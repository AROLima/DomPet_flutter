import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dompet_frontend/src/features/cart/local_cart.dart' show MergeConflict, CartService, localCartProvider;
import 'package:dompet_frontend/src/shared/models/cart.dart';
import 'package:dompet_frontend/src/features/products/products_service.dart';
import 'package:dompet_frontend/src/shared/models/product.dart';

class FakeCartService implements CartService {
  final Map<int, int> _remote = {}; // produtoId -> quantidade
  @override
  Future<Carrinho> addItem({required int produtoId, required int quantidade}) async {
    if (produtoId == 2) {
      // Simula conflito de estoque
      throw MergeConflict();
    }
    _remote.update(produtoId, (v) => v + quantidade, ifAbsent: () => quantidade);
    return _toCart();
  }

  @override
  Future<void> clear() async {
    _remote.clear();
  }

  @override
  Future<Carrinho> getCart() async => _toCart();

  @override
  Future<Carrinho> removeItem(int itemId) async => _toCart();

  @override
  Future<Carrinho> updateItem({required int itemId, required int quantidade}) async => _toCart();

  Carrinho _toCart() {
    final itens = _remote.entries
  .map((e) => ItemCarrinho(itemId: e.key, produtoId: e.key, nome: 'P${e.key}', precoUnitario: 10.0, quantidade: e.value, subtotal: 10.0 * e.value))
        .toList();
    final total = itens.fold<double>(0, (p, e) => p + e.subtotal);
    return Carrinho(itens: itens, total: total);
  }
}

class FakeProductsService extends ProductsService {
  FakeProductsService(Ref ref) : super(ref);
  @override
  Future<ProdutoDetalhe> getDetail(int id) async {
    // produtoId 2 tem estoque 3
    return ProdutoDetalhe(id: id, nome: 'P$id', preco: 10, estoque: id == 2 ? 3 : 10, ativo: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('merge local cart into remote with 409 adjusts qty', () async {
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer(overrides: [
      productsServiceProvider.overrideWith((ref) => FakeProductsService(ref)),
    ]);
    addTearDown(container.dispose);

    final local = await container.read(localCartProvider.future);
    // monta carrinho local: produto 1 (qtd 2), produto 2 (qtd 5) -> 2 conflita
    await local.addItem(produtoId: 1, nome: 'P1', preco: 10, quantidade: 2);
    await local.addItem(produtoId: 2, nome: 'P2', preco: 10, quantidade: 5);

    final remote = FakeCartService();
    await local.mergeIntoRemote(remote);

    final remoteCart = await remote.getCart();
    // produto 1: qtd 2; produto 2: ajustado para min(5, estoque=3) => 3
    expect(remoteCart.itens.firstWhere((i) => i.produtoId == 1).quantidade, 2);
    expect(remoteCart.itens.firstWhere((i) => i.produtoId == 2).quantidade, 3);

    // carrinho local limpo
    final afterLocal = await local.getCart();
    expect(afterLocal.itens, isEmpty);
  });
}


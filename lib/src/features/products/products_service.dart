import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/http/api_client.dart';
import '../../shared/models/page_result.dart';
import '../../shared/models/product.dart';

final productsServiceProvider = Provider<ProductsService>((ref) => ProductsService(ref));

class ProductsService {
  ProductsService(this.ref);
  final Ref ref;
  Dio get _dio => ref.read(dioProvider);

  Future<List<Produto>> getAll() async {
    final res = await _dio.get('/produtos');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Produto.fromJson).toList();
  }

  Future<PageResult<Produto>> search({String? nome, String? categoria, int page = 0, int size = 20, String? sort}) async {
    final res = await _dio.get('/produtos/search', queryParameters: {
      if (nome != null && nome.isNotEmpty) 'nome': nome,
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      'page': page,
      'size': size,
      if (sort != null) 'sort': sort,
    });
    if (res.statusCode == 204 || res.data == null || (res.data is String && (res.data as String).isEmpty)) {
      return PageResult<Produto>(
        content: const [],
        number: page,
        size: size,
        totalElements: 0,
        totalPages: page + 1,
        last: true,
        first: page == 0,
      );
    }
    return PageResult.fromJson(res.data as Map<String, dynamic>, (obj) => Produto.fromJson(obj as Map<String, dynamic>));
  }

  Future<ProdutoDetalhe> getDetail(int id) async {
    final res = await _dio.get('/produtos/$id');
    return ProdutoDetalhe.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ProdutoSugestao>> suggestions(String q, {int limit = 5}) async {
    final res = await _dio.get('/produtos/suggestions', queryParameters: {'q': q, 'limit': limit});
    if (res.statusCode == 204 || res.data == null || (res.data is String && (res.data as String).isEmpty)) {
      return [];
    }
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ProdutoSugestao.fromJson).toList();
  }

  Future<List<String>> getCategorias() async {
    final res = await _dio.get('/produtos/categorias');
    if (res.statusCode == 204 || res.data == null || (res.data is String && (res.data as String).isEmpty)) {
      return [];
    }
    return (res.data as List).map((e) => e.toString()).toList();
  }
}

// Providers
final categoriasProvider = FutureProvider.autoDispose<List<String>>((ref) => ref.read(productsServiceProvider).getCategorias());

@immutable
class ProductsQuery {
  const ProductsQuery({this.nome, this.categoria, this.page = 0, this.size = 20});
  final String? nome;
  final String? categoria;
  final int page;
  final int size;

  ProductsQuery copyWith({String? nome, String? categoria, int? page, int? size}) =>
      ProductsQuery(nome: nome ?? this.nome, categoria: categoria ?? this.categoria, page: page ?? this.page, size: size ?? this.size);

  @override
  bool operator ==(Object other) => other is ProductsQuery && other.nome == nome && other.categoria == categoria && other.page == page && other.size == size;
  @override
  int get hashCode => Object.hash(nome, categoria, page, size);
}

final productsSearchProvider = FutureProvider.autoDispose.family<PageResult<Produto>, ProductsQuery>((ref, q) async {
  return ref.read(productsServiceProvider).search(nome: q.nome, categoria: q.categoria, page: q.page, size: q.size);
});

final productDetailProvider = FutureProvider.autoDispose.family<ProdutoDetalhe, int>((ref, id) => ref.read(productsServiceProvider).getDetail(id));

final suggestionsProvider = FutureProvider.autoDispose.family<List<ProdutoSugestao>, String>((ref, q) => ref.read(productsServiceProvider).suggestions(q));

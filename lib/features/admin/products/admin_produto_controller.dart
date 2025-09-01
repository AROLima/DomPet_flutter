// DIDACTIC: AdminProdutoController — controller for admin product form flows

//
// Purpose:
// - Manage create/edit flows inside the admin product form: validation,
//   mapping UI values to domain models and calling the repository.
//
// Contract:
// - Inputs: form field values and an optional editing id.
// - Outputs: calls into `AdminProdutosRepository` and reports success/failure
//   through notifications or returned futures.
//
// Notes:
// - Keep UI-friendly validation here; avoid embedding network calls in
//   widgets directly. Use this controller to centralize form logic.

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../src/core/http/api_client.dart';
import '../../../src/core/http/problem_detail.dart';
import '../../../src/features/products/products_service.dart';

class AdminProdutoState {
  const AdminProdutoState({
    this.loading = false,
    this.errors = const {},
    this.categorias = const [],
    this.successId,
    this.initial,
    this.deletingId,
  });
  final bool loading;
  final Map<String, String> errors; // field -> msg
  final List<String> categorias;
  final int? successId;
  final Map<String, dynamic>? initial;
  final int? deletingId; // linha em exclusão

  AdminProdutoState copyWith({bool? loading, Map<String, String>? errors, List<String>? categorias, int? successId, Map<String, dynamic>? initial, int? deletingId}) =>
      AdminProdutoState(
        loading: loading ?? this.loading,
        errors: errors ?? this.errors,
        categorias: categorias ?? this.categorias,
        successId: successId ?? this.successId,
        initial: initial ?? this.initial,
        deletingId: deletingId ?? this.deletingId,
      );
}

class AdminProdutoController extends Notifier<AdminProdutoState> {
  @override
  AdminProdutoState build() => const AdminProdutoState();

  Future<void> loadCategorias() async {
  final list = await ref.read(productsServiceProvider).getCategorias();
    state = state.copyWith(categorias: list);
  }

  Future<void> carregarParaEdicao(int id) async {
    state = state.copyWith(loading: true);
    try {
  final detail = await ref.read(productDetailProvider(id).future);
      state = state.copyWith(loading: false, initial: {
        'nome': detail.nome,
        'sku': detail.sku,
        'categoria': detail.categoria,
        'preco': detail.preco,
        'estoque': detail.estoque,
        'descricao': detail.descricao,
        'thumbnailUrl': detail.imagemUrl,
      });
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<int> salvarNovo(Map<String, dynamic> dto) async {
    state = state.copyWith(loading: true, errors: {}, successId: null);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/produtos', data: dto);
      final loc = res.headers.value('location');
      int id;
      if (loc != null) {
        final idStr = Uri.parse(loc).pathSegments.last;
        id = int.tryParse(idStr) ?? -1;
      } else if (res.data is Map && (res.data as Map)['id'] != null) {
        id = (res.data['id'] as num).toInt();
      } else {
        throw Exception('Falha ao criar produto');
      }
      state = state.copyWith(loading: false, successId: id);
      return id;
    } on ProblemDetail catch (p) {
      final errs = <String, String>{};
      for (final e in p.validationErrors ?? const []) {
        final f = e['field']?.toString() ?? '';
        final m = e['message']?.toString() ?? '';
        if (f.isNotEmpty && m.isNotEmpty) errs[f] = m;
      }
      state = state.copyWith(loading: false, errors: errs);
      rethrow;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<int> salvarEdicao(int id, Map<String, dynamic> dto, {String? etag}) async {
    state = state.copyWith(loading: true, errors: {}, successId: null);
    try {
    final dio = ref.read(dioProvider);
    final opts = Options(headers: {if (etag != null) 'If-Match': etag});
    final res = await dio.put('/produtos/$id', data: dto, options: opts);
    final rid = res.statusCode == 204
      ? id
      : (res.data is Map && (res.data as Map)['id'] != null)
        ? (res.data['id'] as num).toInt()
        : id;
      
      state = state.copyWith(loading: false, successId: rid);
      // Invalidate related providers to refresh data
      ref.invalidate(productDetailProvider(id));
      ref.invalidate(productsSearchProvider);
      return rid;
    } on ProblemDetail catch (p) {
      final errs = <String, String>{};
      for (final e in p.validationErrors ?? const []) {
        final f = e['field']?.toString() ?? '';
        final m = e['message']?.toString() ?? '';
        if (f.isNotEmpty && m.isNotEmpty) errs[f] = m;
      }
      state = state.copyWith(loading: false, errors: errs);
      rethrow;
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  Future<void> excluir(int id) async {
    state = state.copyWith(deletingId: id);
    try {
      final dio = ref.read(dioProvider);
      try {
        final res = await dio.delete('/produtos/$id');
        if (res.statusCode == null || res.statusCode! < 200 || res.statusCode! >= 300) {
          throw DioException(requestOptions: res.requestOptions, response: res);
        }
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 405 || code == 404) {
          final res = await dio.patch('/produtos/$id', data: {'ativo': false});
          if (res.statusCode == null || res.statusCode! < 200 || res.statusCode! >= 300) {
            throw DioException(requestOptions: res.requestOptions, response: res);
          }
        } else {
          rethrow;
        }
      }
      // Invalidate providers to refresh the list
      ref.invalidate(productsSearchProvider);
    } catch (e) {
      rethrow;
    } finally {
      // Always clear deletingId state, even on error
      if (state.deletingId == id) {
        state = state.copyWith(deletingId: null);
      }
    }
  }

  Future<void> restaurar(int id) async {
  final dio = ref.read(dioProvider);
  await dio.patch('/produtos/$id', data: {'ativo': true});
  }
}

final adminProdutoControllerProvider = NotifierProvider<AdminProdutoController, AdminProdutoState>(AdminProdutoController.new);

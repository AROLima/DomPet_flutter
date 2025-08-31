import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'admin_produtos_repository.dart';
import '../../../src/core/http/problem_detail.dart';
import '../../../src/features/products/products_service.dart';

class AdminProdutoState {
  const AdminProdutoState({
    this.loading = false,
    this.errors = const {},
    this.categorias = const [],
    this.successId,
    this.initial,
  });
  final bool loading;
  final Map<String, String> errors; // field -> msg
  final List<String> categorias;
  final int? successId;
  final Map<String, dynamic>? initial;

  AdminProdutoState copyWith({bool? loading, Map<String, String>? errors, List<String>? categorias, int? successId, Map<String, dynamic>? initial}) =>
      AdminProdutoState(
        loading: loading ?? this.loading,
        errors: errors ?? this.errors,
        categorias: categorias ?? this.categorias,
        successId: successId ?? this.successId,
        initial: initial ?? this.initial,
      );
}

class AdminProdutoController extends Notifier<AdminProdutoState> {
  @override
  AdminProdutoState build() => const AdminProdutoState();

  Future<void> loadCategorias() async {
    final repo = ref.read(adminProdutosRepositoryProvider);
    final list = await repo.categorias();
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
      final id = await ref.read(adminProdutosRepositoryProvider).create(dto);
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

  Future<int> salvarEdicao(int id, Map<String, dynamic> dto) async {
    state = state.copyWith(loading: true, errors: {}, successId: null);
    try {
      final rid = await ref.read(adminProdutosRepositoryProvider).update(id, dto);
      state = state.copyWith(loading: false, successId: rid);
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
    } finally {
      state = state.copyWith(loading: false);
    }
  }
}

final adminProdutoControllerProvider = NotifierProvider<AdminProdutoController, AdminProdutoState>(AdminProdutoController.new);

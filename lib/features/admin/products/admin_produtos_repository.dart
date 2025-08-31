import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../src/core/http/api_client.dart';

final adminProdutosRepositoryProvider = Provider<AdminProdutosRepository>((ref) => AdminProdutosRepository(ref));

class AdminProdutosRepository {
  AdminProdutosRepository(this.ref);
  final Ref ref;
  Dio get _dio => ref.read(dioProvider);

  Future<List<String>> categorias() async {
    try {
      final res = await _dio.get('/categorias');
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((e) => e.toString()).toList();
      }
    } catch (_) {
      // Fallback para endpoint antigo
    }
    final res = await _dio.get('/produtos/categorias');
    return (res.data as List).map((e) => e.toString()).toList();
  }

  Future<int> create(Map<String, dynamic> dto) async {
    final res = await _dio.post('/produtos', data: dto);
    if (res.headers.map['location']?.isNotEmpty == true) {
      final loc = res.headers.map['location']!.first;
      final idStr = RegExp(r"/produtos/(\\d+)").firstMatch(loc)?.group(1);
      if (idStr != null) return int.parse(idStr);
    }
    if (res.data is Map && (res.data as Map)['id'] != null) {
      return (res.data['id'] as num).toInt();
    }
    throw Exception('Resposta inesperada na criação');
  }

  Future<int> update(int id, Map<String, dynamic> dto) async {
    final res = await _dio.put('/produtos/$id', data: dto);
    if (res.data is Map && (res.data as Map)['id'] != null) {
      return (res.data['id'] as num).toInt();
    }
    return id;
  }
}

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/http/api_client.dart';
import '../../shared/models/order.dart';
import '../../shared/models/page_result.dart';

final ordersServiceProvider = Provider<OrdersService>((ref) => OrdersService(ref));

class OrdersService {
  OrdersService(this.ref);
  final Ref ref;
  Dio get _dio => ref.read(dioProvider);

  Future<Pedido> checkout({required EnderecoDto endereco, String? observacoes, String? metodoPagamento}) async {
    final res = await _dio.post('/pedidos/checkout', data: {
      'enderecoEntrega': endereco.toJson(),
      if (observacoes != null) 'observacoes': observacoes,
      if (metodoPagamento != null) 'metodoPagamento': metodoPagamento,
    });
    return Pedido.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PageResult<Pedido>> list({int page = 0, int size = 20}) async {
    final res = await _dio.get('/pedidos', queryParameters: {'page': page, 'size': size});
    if (res.statusCode == 204 || res.data == null || (res.data is String && (res.data as String).isEmpty)) {
      return PageResult<Pedido>(
        content: const [],
        number: page,
        size: size,
        totalElements: 0,
        totalPages: page + 1,
        last: true,
        first: page == 0,
      );
    }
    return PageResult.fromJson(res.data as Map<String, dynamic>, (obj) => Pedido.fromJson(obj as Map<String, dynamic>));
  }

  Future<Pedido> getById(int id) async {
    final res = await _dio.get('/pedidos/$id');
    return Pedido.fromJson(res.data as Map<String, dynamic>);
  }
}

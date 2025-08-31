import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dompet_frontend/src/core/http/api_client.dart';
import 'package:dompet_frontend/src/features/products/pages/home_page.dart';

class FakeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future? cancelFuture) async {
    if (options.path.startsWith('/produtos/search')) {
      final body = jsonEncode({
        'content': [
          {'id': 1, 'nome': 'Ração Premium', 'preco': 99.9, 'estoque': 5, 'ativo': true},
          {'id': 2, 'nome': 'Brinquedo Bola', 'preco': 19.9, 'estoque': 0, 'ativo': true},
        ],
        'number': 0,
        'size': 20,
        'totalElements': 2,
        'totalPages': 1,
        'first': true,
        'last': true,
      });
      return ResponseBody.fromString(body, 200, headers: {Headers.contentTypeHeader: ['application/json']});
    }
    if (options.path == '/produtos/categorias') {
      return ResponseBody.fromString(jsonEncode([]), 200, headers: {Headers.contentTypeHeader: ['application/json']});
    }
    return ResponseBody.fromString('Not Found', 404);
  }
}

void main() {
  testWidgets('HomePage shows products from /produtos/search', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
    dio.httpClientAdapter = FakeAdapter();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(dio),
      ],
      child: const MaterialApp(home: HomePage()),
    ));

    // first frame (loading)
    await tester.pump();
    // wait futures
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ração Premium'), findsOneWidget);
    expect(find.text('Brinquedo Bola'), findsOneWidget);
  });
}


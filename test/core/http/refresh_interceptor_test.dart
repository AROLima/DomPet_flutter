import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dompet_frontend/src/core/auth/session.dart';
import 'package:dompet_frontend/src/core/http/api_client.dart';

class FakeAdapter implements HttpClientAdapter {
  final List<String> calls = [];
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future? cancelFuture) async {
    calls.add('${options.method} ${options.path}');
    if (options.path == '/auth/refresh' && options.method == 'POST') {
      final body = jsonEncode({'token': 'new_token', 'expiresIn': 600000});
      return ResponseBody.fromString(body, 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    if (options.path == '/protected' && options.method == 'GET') {
      expect(options.headers['Authorization'], 'Bearer new_token');
      final body = jsonEncode({'ok': true});
      return ResponseBody.fromString(body, 200, headers: {
        Headers.contentTypeHeader: ['application/json']
      });
    }
    return ResponseBody.fromString('Not Found', 404);
  }
}

class FakeSessionNotifier extends SessionNotifier {
  FakeSessionNotifier(this.initial);
  final Session initial;
  @override
  Future<Session?> build() async => initial;
}

void main() {
  test('Auth interceptor refreshes token when expiring soon and retries request', () async {
    final container = ProviderContainer(overrides: [
      sessionProvider.overrideWith(() => FakeSessionNotifier(Session(token: 'old', expiresAt: DateTime.now().add(const Duration(minutes: 1))))),
    ]);
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);
    final adapter = FakeAdapter();
    dio.httpClientAdapter = adapter;

    final res = await dio.get('/protected');
    expect(res.statusCode, 200);
    expect(adapter.calls, containsAllInOrder(['POST /auth/refresh', 'GET /protected']));
  });
}


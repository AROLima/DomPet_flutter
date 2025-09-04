import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/session.dart';
import '../config/app_config.dart';
import 'etag_cache.dart';
import 'problem_detail.dart';

// Centralized Dio client with interceptors (host normalization, API version, auth, ETag cache, ProblemDetail parsing)
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && ((status >= 200 && status < 400) || status == 304),
    ),
  );

  dio.interceptors.addAll([
    _HostNormalizeInterceptor(),
    _ApiVersionInterceptor(ref),
    _AuthInterceptor(ref),
    _EtagInterceptor(ref),
    _ProblemDetailInterceptor(),
    LogInterceptor(requestBody: false, responseBody: false),
  ]);

  return dio;
});

class _HostNormalizeInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final p = options.path;
    if ((p.startsWith('http://') || p.startsWith('https://')) && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final u = Uri.parse(p);
        if (u.host == 'localhost' || u.host == '127.0.0.1') {
          options.path = u.replace(host: '10.0.2.2').toString();
        }
      } catch (_) {}
    }
    handler.next(options);
  }
}

class _ApiVersionInterceptor extends Interceptor {
  _ApiVersionInterceptor(this.ref);
  final Ref ref;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final ver = response.headers.value('X-API-Version');
    if (ver != null) {
      ref.read(apiVersionProvider.notifier).state = ver;
    }
    super.onResponse(response, handler);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.ref);
  final Ref ref;
  bool _refreshing = false;
  final _queue = <Completer<void>>[];

  Future<void> _enqueueWhileRefreshing() async {
    final c = Completer<void>();
    _queue.add(c);
    await c.future;
  }

  void _flushQueue() {
    for (final c in _queue) {
      if (!c.isCompleted) c.complete();
    }
    _queue.clear();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final session = ref.read(sessionProvider).value;

    final isLogin = options.path.startsWith('/auth/login');
    final isRegister = options.path.startsWith('/auth/register');

    if (session != null) {
      final isRefresh = options.path.startsWith('/auth/refresh');
      if (!isRefresh && session.isExpiringWithin(const Duration(minutes: 2))) {
        await _tryRefreshToken();
      }
      if (!isLogin && !isRegister) {
        final token = ref.read(sessionProvider).value?.token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    if (response?.statusCode == 401) {
      final retried = err.requestOptions.extra['retried'] == true;
      try {
        if (!retried) {
          await _tryRefreshToken();
          final token = ref.read(sessionProvider).value?.token;
          if (token == null) {
            await ref.read(sessionProvider.notifier).clear();
            return handler.next(err);
          }
          final clone = await _retryRequest(err.requestOptions, token);
          return handler.resolve(clone);
        }
      } catch (_) {
        await ref.read(sessionProvider.notifier).clear();
      }
    }
    handler.next(err);
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions req, String token) async {
    final dio = ref.read(dioProvider);
    final opts = Options(
      method: req.method,
      headers: Map<String, dynamic>.from(req.headers)..['Authorization'] = 'Bearer $token',
      responseType: req.responseType,
      contentType: req.contentType,
      followRedirects: req.followRedirects,
      listFormat: req.listFormat,
      receiveDataWhenStatusError: req.receiveDataWhenStatusError,
      requestEncoder: req.requestEncoder,
      responseDecoder: req.responseDecoder,
      sendTimeout: req.sendTimeout,
      receiveTimeout: req.receiveTimeout,
      extra: {...req.extra, 'retried': true},
    );
    return dio.request<dynamic>(
      req.path,
      data: req.data,
      queryParameters: req.queryParameters,
      options: opts,
      cancelToken: req.cancelToken,
      onReceiveProgress: req.onReceiveProgress,
      onSendProgress: req.onSendProgress,
    );
  }

  Future<void> _tryRefreshToken() async {
    if (_refreshing) {
      await _enqueueWhileRefreshing();
      return;
    }
    _refreshing = true;
    try {
      final dio = ref.read(dioProvider);
      final current = ref.read(sessionProvider).value;
      if (current == null) return;
      final res = await dio.post('/auth/refresh');
      final token = res.data['token'] as String;
      final expiresInMs = (res.data['expiresIn'] as num).toInt();
      await ref.read(sessionProvider.notifier).setSession(token, Duration(milliseconds: expiresInMs));
    } finally {
      _refreshing = false;
      _flushQueue();
    }
  }
}

class _ProblemDetailInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.data is Map<String, dynamic>) {
      try {
        final pd = ProblemDetail.fromJson(err.response!.data as Map<String, dynamic>);
        handler.reject(err.copyWith(error: pd));
        return;
      } catch (_) {}
    }
    super.onError(err, handler);
  }
}

class _EtagInterceptor extends Interceptor {
  _EtagInterceptor(this.ref);
  final Ref ref;

  bool _isProductDetail(RequestOptions options) =>
      options.method == 'GET' && RegExp(r'^/produtos/\d+$').hasMatch(options.path);

  bool _isProductsList(RequestOptions options) =>
      options.method == 'GET' && options.path == '/produtos' && (options.queryParameters.isEmpty || options.queryParameters.isNotEmpty);

  bool _isProductsSearch(RequestOptions options) =>
      options.method == 'GET' && options.path == '/produtos/search';

  bool _isProductsSuggestions(RequestOptions options) =>
      options.method == 'GET' && options.path == '/produtos/suggestions';

  String _cacheKey(RequestOptions options) {
    if (options.queryParameters.isEmpty) return options.path;
    final qp = Map<String, dynamic>.from(options.queryParameters);
    final keys = qp.keys.toList()..sort();
    final pairs = keys.map((k) => '$k=${qp[k]}').join('&');
    return '${options.path}?$pairs';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  if (_isProductDetail(options) || _isProductsList(options) || _isProductsSearch(options) || _isProductsSuggestions(options)) {
      final cache = await ref.read(etagCacheProvider.future);
      final etag = cache.getEtag(_cacheKey(options));
      if (etag != null) {
        options.headers['If-None-Match'] = etag;
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final req = response.requestOptions;
    final isCacheableGet = req.method == 'GET' && (
      RegExp(r'^/produtos/\d+$').hasMatch(req.path) ||
      req.path == '/produtos' ||
      req.path == '/produtos/search' ||
      req.path == '/produtos/suggestions'
    );
    if (isCacheableGet) {
      final cache = await ref.read(etagCacheProvider.future);
      final etag = response.headers.value('etag');
      if (etag != null && response.statusCode == 200) {
        cache.save(_cacheKey(req), etag, response.data);
      }
      if (response.statusCode == 304) {
        final cached = cache.get(_cacheKey(req));
        if (cached != null) {
          return handler.resolve(Response(
            data: cached.data,
            headers: response.headers,
            requestOptions: req,
            statusCode: 200,
            statusMessage: 'Not Modified (served from cache)',
          ));
        }
      }
    }
    handler.next(response);
  }
}

// DIDACTIC: HTTP client and interceptors
//
// Purpose:
// - Provide a single, app-wide `Dio` instance configured with base URL,
//   sensible timeouts and a set of interceptors that implement cross-cutting
//   behaviors (auth, ETag caching, ProblemDetail parsing, API version capture).
//
// Contract / responsibilities:
// - `dioProvider` yields a ready-to-use `Dio` client. Interceptors are allowed
//   to update Riverpod state (e.g., session, apiVersionProvider) but should
//   avoid performing UI work directly.
// Notas didaticas sobre o cliente HTTP:
//   failed request once after refreshing. Clients should expect a possible
//   retry on 401 but no infinite loops.
//
// - _AuthInterceptor faz refresh proativo e gerencia uma fila enquanto o refresh está em andamento.
// Edge cases & notes:
// - Host normalization rewrites absolute localhost URLs to `10.0.2.2` when
//   running on Android emulator to enable local backend access.
// - ETag interceptor works with `etagCacheProvider` and can serve cached
//   bodies when the server returns 304 Not Modified.

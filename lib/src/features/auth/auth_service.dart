import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/http/api_client.dart';
import '../../core/auth/session.dart';
import '../../shared/models/auth_response.dart';
import '../cart/local_cart.dart';
import '../cart/cart_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

class AuthService {
  AuthService(this.ref);
  final Ref ref;

  Dio get _dio => ref.read(dioProvider);

  Future<void> register({required String nome, required String email, required String senha}) async {
    final res = await _dio.post('/auth/register', data: {
      'nome': nome,
      'email': email,
      'senha': senha,
    });
    final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await ref.read(sessionProvider.notifier).setSession(auth.token, Duration(milliseconds: auth.expiresIn));
    await _mergeLocalCart();
  }

  Future<void> login({required String email, required String senha}) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'senha': senha,
    });
    final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await ref.read(sessionProvider.notifier).setSession(auth.token, Duration(milliseconds: auth.expiresIn));
    await _mergeLocalCart();
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      await ref.read(sessionProvider.notifier).clear();
    }
  }

  Future<void> logoutAll() async {
    try {
      await _dio.post('/auth/logout-all');
    } finally {
      await ref.read(sessionProvider.notifier).clear();
    }
  }

  Future<void> _mergeLocalCart() async {
    final local = await ref.read(localCartProvider.future);
    final cartService = ref.read(cartServiceProvider);
    await local.mergeIntoRemote(cartService);
  }
}


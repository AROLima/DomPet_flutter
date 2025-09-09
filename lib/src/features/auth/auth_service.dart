// DIDACTIC: AuthService — authentication & session management
//
// Purpose:
// - Provide login, register, logout and session refresh operations.
//
// Contract:
// - Inputs: credentials or refresh token when applicable.
// - Outputs: a persisted Session (auth token + tokenVersion).
// - Error modes: returns parsed ProblemDetail on RFC-7807 responses; network
//   errors surface as DioExceptions.
//
// Notes:
// - Keep token persistence and refresh logic centralized here to avoid
//   duplicate logic across the app.

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/http/api_client.dart';
import '../../core/auth/session.dart';
import '../../shared/models/auth_response.dart';
import '../cart/local_cart.dart';
import '../cart/cart_service.dart';

// Small authentication service used by UI screens.
//
// Responsibilities:
// - call the backend endpoints for register/login/logout
// - on successful login/register it stores the JWT in `sessionProvider`
// - merges any local cart into the remote cart to preserve user actions done
//   before authentication
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
    // Store session and proactively merge local cart into the server-side cart
    await ref.read(sessionProvider.notifier).setSession(auth.token, Duration(milliseconds: auth.expiresIn));
  // Invalidate profile so UI fetches fresh /usuarios/me for the new session
  ref.invalidate(profileProvider);
    await _mergeLocalCart();
  }

  Future<void> login({required String email, required String senha}) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'senha': senha,
    });
    final auth = AuthResponse.fromJson(res.data as Map<String, dynamic>);
    await ref.read(sessionProvider.notifier).setSession(auth.token, Duration(milliseconds: auth.expiresIn));
  ref.invalidate(profileProvider);
    await _mergeLocalCart();
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } finally {
      // Always clear local session even if network fails
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


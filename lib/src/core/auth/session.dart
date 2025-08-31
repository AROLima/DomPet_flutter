import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class Session {
  Session({required this.token, required this.expiresAt});
  final String token;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool isExpiringWithin(Duration d) => DateTime.now().isAfter(expiresAt.subtract(d));

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
      };
  static Session? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Session(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

final _storageProvider = Provider((ref) => const FlutterSecureStorage());

class SessionNotifier extends AsyncNotifier<Session?> {
  static const _key = 'session_v1';
  Timer? _refreshTimer;

  @override
  Future<Session?> build() async {
    final storage = ref.read(_storageProvider);
    final token = await storage.read(key: '${_key}_token');
    final expiresAtStr = await storage.read(key: '${_key}_expiresAt');
    if (token == null || expiresAtStr == null) return null;
    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return null;
    final s = Session(token: token, expiresAt: expiresAt);
    _scheduleProactiveRefresh(s);
    return s;
  }

  Future<void> setSession(String token, Duration expiresIn) async {
    final s = Session(token: token, expiresAt: DateTime.now().add(expiresIn));
    state = AsyncData(s);
    final storage = ref.read(_storageProvider);
    await storage.write(key: '${_key}_token', value: s.token);
    await storage.write(key: '${_key}_expiresAt', value: s.expiresAt.toIso8601String());
    _scheduleProactiveRefresh(s);
  }

  Future<void> clear() async {
    _refreshTimer?.cancel();
    state = const AsyncData(null);
    final storage = ref.read(_storageProvider);
    await storage.delete(key: '${_key}_token');
    await storage.delete(key: '${_key}_expiresAt');
  }

  void _scheduleProactiveRefresh(Session s) {
    _refreshTimer?.cancel();
    final now = DateTime.now();
    final triggerAt = s.expiresAt.subtract(const Duration(minutes: 2));
    final delay = triggerAt.isAfter(now) ? triggerAt.difference(now) : Duration.zero;
    _refreshTimer = Timer(delay, _tryRefreshToken);
  }

  Future<void> _tryRefreshToken() async {
    // O interceptor HTTP chamará /auth/refresh automaticamente antes de requests.
    // Este timer assegura que mesmo sem requests recentes, iremos revalidar próximo ao vencimento.
    // Aqui podemos acionar um ping leve se necessário no futuro.
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);


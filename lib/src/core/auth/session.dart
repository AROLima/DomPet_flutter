// Session model and persistence provider
// Purpose: hold token and expiry, persist to secure storage, expose provider.

import 'dart:async';
import 'dart:convert';
// import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';

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

  List<String> get roles {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return const [];
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final payload = json.decode(utf8.decode(base64.decode(normalized))) as Map<String, dynamic>;
      final set = <String>{};
      void addAll(dynamic v) {
        if (v is String) {
          for (final s in v.split(RegExp(r'[ ,]'))) {
            if (s.isNotEmpty) set.add(s.trim());
          }
        } else if (v is List) {
          for (final e in v) {
            if (e is String) set.add(e);
          }
        }
      }
      if (payload['roles'] != null) addAll(payload['roles']);
      if (payload['authorities'] != null) addAll(payload['authorities']);
      if (payload['scope'] != null) addAll(payload['scope']);
      if (payload['scopes'] != null) addAll(payload['scopes']);
      final realm = payload['realm_access'];
      if (realm is Map && realm['roles'] != null) addAll(realm['roles']);
      return set.toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

class SessionNotifier extends AsyncNotifier<Session?> {
  static const _key = 'session_v1';
  Timer? _refreshTimer;

  @override
  Future<Session?> build() async {
    try {
      final storage = ref.read(storageProvider);
      final token = await storage.read(key: '${_key}_token');
      final expiresAtStr = await storage.read(key: '${_key}_expiresAt');
      if (token == null || expiresAtStr == null) return null;
      final expiresAt = DateTime.tryParse(expiresAtStr);
      if (expiresAt == null) return null;
      final s = Session(token: token, expiresAt: expiresAt);
      _scheduleProactiveRefresh(s);
      return s;
    } catch (_) {
      return null;
    }
  }

  Future<void> setSession(String token, Duration expiresIn) async {
  // Clear any previous session artifacts before storing new token
  final storage = ref.read(storageProvider);
  await storage.delete(key: '${_key}_token');
  await storage.delete(key: '${_key}_expiresAt');
  final s = Session(token: token, expiresAt: DateTime.now().add(expiresIn));
  state = AsyncData(s);
  await storage.write(key: '${_key}_token', value: s.token);
  await storage.write(key: '${_key}_expiresAt', value: s.expiresAt.toIso8601String());
  _scheduleProactiveRefresh(s);
  }

  Future<void> clear() async {
    _refreshTimer?.cancel();
    state = const AsyncData(null);
    final storage = ref.read(storageProvider);
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
    // Placeholder: actual network refresh is handled by the HTTP layer.
  }
}

final storageProvider = Provider((ref) => const FlutterSecureStorage());
final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);


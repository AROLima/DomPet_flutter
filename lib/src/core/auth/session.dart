// DIDACTIC: Session model and persistence provider
//
// Purpose:
// - Represent an authenticated user's JWT session, expose expiry helpers,
//   and persist the token securely between app launches.
//
// Contract:
// - `Session` holds `token` and `expiresAt` and provides convenience helpers
//   (isExpired, roles extraction).
// - `SessionNotifier` is an AsyncNotifier that loads/saves the session to
//   `FlutterSecureStorage` and exposes reactive session state via
//   `sessionProvider`.
//
// Security notes:
// - Tokens are stored in secure storage; avoid logging full tokens.

import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

part 'session_provider.g.dart';

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

  /// Extracts roles from JWT payload if present. Supports common claims:
  /// `roles`, `authorities`, `scope`/`scopes` and `realm_access.roles`.
  /// This is a best-effort helper for UI decisions (show/hide admin links).
  List<String> get roles {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return const [];
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      // pad base64
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

// Secure storage provider used to persist token between launches.
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
    // The HTTP interceptor will attempt a refresh automatically before requests.
    // This timer guarantees a refresh attempt even when the app is idle near
    // token expiration. Currently it's a no-op placeholder but kept for future
    // proactive network pings or telemetry.
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);


// DIDACTIC: ETag cache — persistent small-store for HTTP 304 caching
// Purpose:
// - Provide a small persistent cache for HTTP GET responses keyed by path
//   using ETag values and cached response bodies when a 304 Not Modified
//   response occurs.
// Contract:
// - Data must remain small (SharedPreferences), and keys use request paths.
// - `getEtag`, `get` and `save` provide the minimal API used by the HTTP
//   interceptor.
// Edge cases / Notes:
// - This cache is in-memory-backed but persisted on writes; it's intentionally
//   simple for study purposes.

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EtagEntry {
  EtagEntry(this.etag, this.data);
  final String etag;
  final dynamic data;

  Map<String, dynamic> toJson() => {
        'etag': etag,
        'data': data,
      };
  static EtagEntry fromJson(Map<String, dynamic> json) => EtagEntry(
        json['etag'] as String,
        json['data'],
      );
}

class EtagCache {
  EtagCache(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'etag_cache_v1';
  final Map<String, EtagEntry> _mem = {};

  void _load() {
    if (_mem.isNotEmpty) return;
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    for (final e in map.entries) {
      _mem[e.key] = EtagEntry.fromJson(e.value as Map<String, dynamic>);
    }
  }

  void _save() {
    final map = _mem.map((key, value) => MapEntry(key, value.toJson()));
    _prefs.setString(_key, jsonEncode(map));
  }

  String? getEtag(String path) {
    _load();
    return _mem[path]?.etag;
  }

  EtagEntry? get(String path) {
    _load();
    return _mem[path];
  }

  void save(String path, String etag, dynamic data) {
    _load();
    _mem[path] = EtagEntry(etag, data);
    _save();
  }
}

final etagCacheProvider = FutureProvider<EtagCache>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return EtagCache(prefs);
});


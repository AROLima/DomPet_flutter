import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Onde alterar baseUrl e flavor (dev/prod).
/// Ajuste aqui ou use --dart-define em builds futuros.
/// Ex.: flutter run --dart-define=BASE_URL=http://10.0.2.2:8080 --dart-define=FLAVOR=dev
class AppConfig {
  AppConfig({required this.baseUrl, required this.flavor});

  final String baseUrl;
  final String flavor; // "dev" | "prod"

  static AppConfig fromEnv() {
    const envBase = String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8080');
    const envFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

    String base = envBase;
    try {
      final uri = Uri.parse(envBase);
      final isLocalHost = uri.host == 'localhost' || uri.host == '127.0.0.1';
      // Reescreve localhost -> 10.0.2.2 apenas em Android nativo (não Web)
      if (isLocalHost && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        base = uri.replace(host: '10.0.2.2').toString();
      }
    } catch (_) {
      // mantém valor original se parsing falhar
    }

    return AppConfig(baseUrl: base, flavor: envFlavor);
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnv());

/// Header X-API-Version exposto para debug/logs.
final apiVersionProvider = StateProvider<String?>((ref) => null);

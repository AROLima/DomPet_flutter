// DIDACTIC: Application configuration and environment handling
//
// Purpose:
// - Centralize runtime configuration resolved from `--dart-define` variables
//   such as `BASE_URL` and `FLAVOR`.
//
// Contract:
// - `AppConfig.fromEnv()` reads compile-time environment variables and
//   performs host rewrites when running on an Android emulator (localhost -> 10.0.2.2).
// - `appConfigProvider` exposes the resolved configuration via Riverpod.
//
// Notes:
// - Keep environment-specific logic here to avoid scattering platform checks
//   across the codebase.
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
      // Rewrite localhost -> 10.0.2.2 only on Android native (not Web).
      if (isLocalHost && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        base = uri.replace(host: '10.0.2.2').toString();
      }
    } catch (_) {
      // keep original if parsing fails
    }

    return AppConfig(baseUrl: base, flavor: envFlavor);
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnv());

/// Header X-API-Version exposed for debug/logging and introspection.
final apiVersionProvider = StateProvider<String?>((ref) => null);

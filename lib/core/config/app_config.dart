/// Compile-time environment configuration for the mobile API.
///
/// Examples:
/// flutter run -d chrome --dart-define=API_BASE_URL=https://skillserve-web-backend.onrender.com/api
/// flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
class AppConfig {
  AppConfig._();

  static const String appName = 'SkillServe';

  /// REST API root (Render-hosted Laravel + Neon Postgres).
  /// Override locally with:
  ///   --dart-define=API_BASE_URL=http://localhost:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://skillserve-web-backend.onrender.com/api',
  );

  static const Duration apiTimeout = Duration(seconds: 15);
}

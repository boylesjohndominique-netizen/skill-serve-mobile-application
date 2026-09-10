/// Compile-time environment configuration for the mobile API.
///
/// Examples:
/// flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
/// flutter run --dart-define=USE_MOCK_DATA=true
class AppConfig {
  AppConfig._();

  static const String appName = 'SkillServe';

  /// Laravel REST API root. Override for an Android emulator or physical phone.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  /// Live API is enabled by default. Set USE_MOCK_DATA=true for standalone demo mode.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );

  static const Duration apiTimeout = Duration(seconds: 15);
}

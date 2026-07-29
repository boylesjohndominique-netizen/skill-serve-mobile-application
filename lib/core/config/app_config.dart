/// Environment configuration placeholder.
///
/// Swap [baseUrl] for the real Laravel API root once the backend is
/// available, and flip [useMockData] to false to route through
/// [ApiClient] instead of the in-memory mock services.
class AppConfig {
  AppConfig._();

  static const String appName = 'SkillLink';

  /// Laravel REST API base URL. Update when the backend is deployed.
  static const String baseUrl = 'http://localhost:8000/api';

  /// While true, every service in lib/services returns mock data instead
  /// of calling the network — lets the UI be built and demoed standalone.
  static const bool useMockData = true;

  static const Duration apiTimeout = Duration(seconds: 15);
}

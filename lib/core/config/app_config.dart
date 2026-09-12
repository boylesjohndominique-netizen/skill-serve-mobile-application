/// Compile-time environment configuration for the mobile API.
///
/// Examples:
/// flutter run -d chrome --dart-define=API_BASE_URL=https://skillserve-web-backend.onrender.com/api
/// flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
class AppConfig {
  AppConfig._();

  static const String appName = 'SkillServe';

  /// Google OAuth **Web** client ID (GCP project `skillserve-508412`).
  /// Sent as the `serverClientId` to google_sign_in so it returns an ID token
  /// on Android; the backend must have the same value in `GOOGLE_CLIENT_ID`.
  /// Override with: --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '505637339796-b7fi5m130m6amski1r4nckfhh0ge8d4g.apps.googleusercontent.com',
  );

  /// REST API root (Render-hosted Laravel + Neon Postgres).
  /// Override locally with:
  ///   --dart-define=API_BASE_URL=http://localhost:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://skillserve-web-backend.onrender.com/api',
  );

  /// Per-request send/receive timeout once a connection is established.
  /// Must exceed the free-tier Render cold-start time (~60-75 s): the
  /// connection is accepted quickly but the response arrives only after
  /// the sleeping server boots, so a short receive timeout fails every
  /// first request after idle. 120 s covers the slowest observed boot
  /// (~66 s) with headroom.
  static const Duration apiTimeout = Duration(seconds: 120);

  /// Connection-establishment timeout. The Render proxy accepts the TCP
  /// connection immediately, so this rarely binds; kept generous anyway.
  static const Duration connectTimeout = Duration(seconds: 90);
}

/// Compile-time environment configuration for the mobile API.
///
/// Defaults to production (Render). To target the local Docker backend:
///   flutter run -d edge --dart-define-from-file=env/local.json
/// Production explicitly:
///   flutter run -d edge --dart-define-from-file=env/production.json
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
  ///   --dart-define-from-file=env/local.json
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://skillserve-web-backend.onrender.com/api',
  );

  /// Laravel Reverb (WebSocket) app key — public, same as the web admin's
  /// VITE_REVERB_APP_KEY. Must match REVERB_APP_KEY on the backend.
  /// Override with: --dart-define=REVERB_APP_KEY=...
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'skillserve',
  );

  /// WebSocket endpoint. Defaults to the API host: wss on 443 for https
  /// (Render routes /app/* to Reverb), ws on 8080 for local http.
  /// Override with --dart-define=REVERB_HOST / REVERB_PORT / REVERB_SCHEME.
  static Uri get reverbUri {
    final api = Uri.parse(baseUrl);
    const host = String.fromEnvironment('REVERB_HOST');
    const port = int.fromEnvironment('REVERB_PORT');
    const scheme = String.fromEnvironment('REVERB_SCHEME');
    final secure = scheme.isNotEmpty ? scheme == 'https' : api.scheme == 'https';

    return Uri(
      scheme: secure ? 'wss' : 'ws',
      host: host.isNotEmpty ? host : api.host,
      port: port != 0 ? port : (secure ? 443 : 8080),
      path: '/app/$reverbAppKey',
      queryParameters: const {'protocol': '7', 'client': 'skillserve-flutter', 'version': '1.0'},
    );
  }

  /// Channel authorization endpoint for private channels.
  static String get broadcastingAuthUrl => '${baseUrl.replaceFirst(RegExp(r'/api/?$'), '')}/api/broadcasting/auth';

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

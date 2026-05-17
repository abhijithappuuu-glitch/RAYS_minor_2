/// API endpoint constants
class ApiConstants {
  ApiConstants._();

  // ── URLs ────────────────────────────────────────────
  /// Production REST API
  static const String baseUrl = 'https://api.rakshak.ai/v1';
  static const String stagingUrl = 'https://staging-api.rakshak.ai/v1';
  /// Local dev — Android emulator routes 10.0.2.2 to the host machine
  static const String localDevUrl = 'http://10.0.2.2:5000/api/v1';

  // ── Timeouts (milliseconds) ──────────────────────────
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // ── Endpoints ────────────────────────────────────────
  static const String predict        = '/predict';
  static const String syncStressData = '/stress/sync';
  static const String fetchInsights  = '/insights';
  static const String userProfile    = '/user/profile';
  static const String anonymousReport = '/reports/anonymous';
  static const String interventions  = '/interventions';
  static const String health         = '/health';

  // ── Headers ───────────────────────────────────────────
  static const String authHeader     = 'Authorization';
  static const String contentType    = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String deviceIdHeader = 'X-Device-Id';
  static const String appVersionHeader = 'X-App-Version';
  /// ML backend API key header (must match backend config API_KEY_HEADER)
  static const String apiKeyHeader   = 'X-API-Key';

  // ── API Keys ─────────────────────────────────────────
  /// Mobile client key — matches backend .env VALID_API_KEYS
  static const String mobileApiKey  = 'rakshak-mobile-key-2026';
}

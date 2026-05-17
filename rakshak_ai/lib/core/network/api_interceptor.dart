import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:rakshak_ai/core/constants/api_constants.dart';
import 'package:rakshak_ai/core/security/secure_storage_service.dart';
import 'package:rakshak_ai/core/di/injection.dart';

/// Dio interceptor for adding auth tokens, HMAC signing, replay protection,
/// device info, and error handling.
class ApiInterceptor extends Interceptor {
  static const _uuid = Uuid();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = getIt<SecureStorageService>();

    // ── Auth token ───────────────────────────────────────
    final token = await storage.read('auth_token');
    if (token != null) {
      options.headers[ApiConstants.authHeader] = 'Bearer $token';
    }

    // ── Device identifier ────────────────────────────────
    final deviceId = await storage.read('device_id');
    if (deviceId != null) {
      options.headers[ApiConstants.deviceIdHeader] = deviceId;
    }

    options.headers[ApiConstants.appVersionHeader] = '1.0.0';

    // ── Replay Protection ────────────────────────────────
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = _uuid.v4();

    options.headers['X-Request-Timestamp'] = timestamp;
    options.headers['X-Request-Nonce'] = nonce;

    // ── API Key — sent on every request ─────────────────
    // Use the mobile client API key (matches backend VALID_API_KEYS).
    // Prefer a runtime override stored in secure storage (for key rotation);
    // fall back to the compiled-in constant.
    final storedKey = await storage.read('api_key');
    final apiKey = (storedKey != null && storedKey.isNotEmpty)
        ? storedKey
        : ApiConstants.mobileApiKey;
    options.headers[ApiConstants.apiKeyHeader] = apiKey;

    // ── HMAC-SHA256 Request Signing ──────────────────────
    // Matches backend auth.py validation: signature = HMAC(key, timestamp + nonce + body)
    final bodyString = options.data != null ? jsonEncode(options.data) : '';
    final signaturePayload = '$timestamp$nonce$bodyString';

    final hmacKey = utf8.encode(apiKey);
    final hmac = Hmac(sha256, hmacKey);
    final digest = hmac.convert(utf8.encode(signaturePayload));
    final signature = digest.toString();

    options.headers['X-Request-Signature'] = signature;

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired — trigger refresh or re-auth
      _handleUnauthorized();
    } else if (err.response?.statusCode == 429) {
      // Rate limited — back off
    }
    handler.next(err);
  }

  void _handleUnauthorized() async {
    // Clear expired token
    final storage = getIt<SecureStorageService>();
    await storage.delete('auth_token');
    // App should navigate to onboarding / re-auth flow
  }
}

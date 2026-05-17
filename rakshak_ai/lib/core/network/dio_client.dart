import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rakshak_ai/core/constants/api_constants.dart';
import 'package:rakshak_ai/core/network/api_interceptor.dart';
import 'package:rakshak_ai/core/security/ssl_pinning.dart';

/// Configured Dio HTTP client for all API calls.
///
/// In debug builds: points to the local Flask backend on the Android emulator
/// host (10.0.2.2:5000) and skips SSL pinning so plain HTTP works.
/// In release builds: uses the production HTTPS endpoint with SSL pinning.
class DioClient {
  late final Dio _dio;

  DioClient() {
    final baseUrl =
        kDebugMode ? ApiConstants.localDevUrl : ApiConstants.baseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
        headers: {
          ApiConstants.contentType: ApiConstants.applicationJson,
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      ApiInterceptor(),
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
    ]);

    // SSL Pinning — only in release builds; local HTTP doesn't need it
    if (!kDebugMode) {
      _dio.httpClientAdapter = SSLPinningService.createPinnedAdapter();
    }
  }

  Dio get dio => _dio;
}

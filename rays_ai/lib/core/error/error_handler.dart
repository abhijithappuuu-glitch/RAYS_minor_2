import 'package:logger/logger.dart';
import 'package:rakshak_ai/core/error/failures.dart';

/// Centralized error handler with logging
class ErrorHandler {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  static void handleError(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) {
      _logger.w('Failure: ${error.message}');
    } else {
      _logger.e('Unexpected error', error: error, stackTrace: stackTrace);
    }
  }

  static void logInfo(String message) {
    _logger.i(message);
  }

  static void logDebug(String message) {
    _logger.d(message);
  }

  static void logWarning(String message) {
    _logger.w(message);
  }
}

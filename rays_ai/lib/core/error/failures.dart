/// Base failure class for error handling
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Network-related failures (timeout, no connection)
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Server-side failures (4xx, 5xx)
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

/// Local database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Security check failures (root detection, tamper, etc.)
class SecurityFailure extends Failure {
  const SecurityFailure(super.message);
}

/// Encryption/Decryption failures
class EncryptionFailure extends Failure {
  const EncryptionFailure(super.message);
}

/// Catch-all unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

// Custom exceptions for network operations
// Provides deterministic error classification and recovery hints

abstract class NetworkException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  NetworkException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;

  /// Whether this error is retryable (transient failures)
  bool get isRetryable => false;

  /// User-facing error message (safe for display)
  String get userMessage => message;
}

/// Network connectivity lost or no internet
class NoInternetException extends NetworkException {
  NoInternetException({
    super.message = 'No internet connection',
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;

  @override
  String get userMessage => 'Connection lost. Retrying...';
}

/// Request/response timeout
class TimeoutException extends NetworkException {
  final Duration timeout;

  TimeoutException({
    required this.timeout,
    super.message = 'Request timeout',
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => true;

  @override
  String get userMessage =>
      'Action taking longer than expected. Still trying...';
}

/// HTTP status code errors (4xx, 5xx)
class HttpException extends NetworkException {
  final int statusCode;
  final dynamic responseBody;

  HttpException({
    required this.statusCode,
    required super.message,
    this.responseBody,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => statusCode >= 500; // 5xx errors are retryable

  @override
  String get userMessage {
    if (statusCode >= 500) {
      return 'Server error. Please try again later.';
    }
    if (statusCode == 429) {
      return 'Too many requests. Please wait a moment.';
    }
    return message;
  }
}

/// Backend rejected action due to policy (400 with specific error code)
class SafeRejectException extends NetworkException {
  final String errorCode;
  final Map<String, dynamic> context;
  final bool retryAllowed;

  SafeRejectException({
    required this.errorCode,
    required super.message,
    this.context = const {},
    this.retryAllowed = false,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  String get userMessage => message;
}

/// Clarification required from player (action is ambiguous)
class ClarificationRequiredException extends NetworkException {
  final String prompt;
  final Map<String, dynamic> clarificationContext;
  final String clientTurnIdForRetry;

  ClarificationRequiredException({
    required this.prompt,
    required this.clientTurnIdForRetry,
    this.clarificationContext = const {},
    super.message = 'Clarification required',
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  String get userMessage => 'The story needs clarification: $prompt';
}

/// Idempotency conflict (same key, different payload)
class IdempotencyConflictException extends NetworkException {
  final String clientTurnId;
  final String originalRequestHash;
  final String incomingRequestHash;

  IdempotencyConflictException({
    required this.clientTurnId,
    required this.originalRequestHash,
    required this.incomingRequestHash,
    super.message = 'Idempotency conflict detected',
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  String get userMessage =>
      'Action conflict detected. Please try again with a different action.';
}

/// JSON deserialization error (malformed response)
class DeserializationException extends NetworkException {
  final String jsonPath; // e.g., "response.character_state.inventory"

  DeserializationException({
    required super.message,
    required this.jsonPath,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  String get userMessage =>
      'Server responded with unexpected format. Please try again.';
}

/// Unknown/unhandled error
class UnknownNetworkException extends NetworkException {
  UnknownNetworkException({
    super.message = 'An unknown error occurred',
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRetryable => false;

  @override
  String get userMessage => 'An unexpected error occurred. Please try again.';
}

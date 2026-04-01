/// Network configuration and constants
class NetworkConfig {
  // Base URL configuration
  // HTTPS is REQUIRED for all environments (no HTTP allowed)
  // Override via HttpClientService constructor for environment-specific URLs:
  //   - Development: 'https://localhost:3000/api' (allow self-signed certs temporarily)
  //   - Production: 'https://api.nexus-tales.com/api' (certificate pinning should be enabled)
  static const String baseUrl = 'https://localhost:3000/api';

  // Timeout durations
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration turnSubmissionTimeout = Duration(seconds: 60); // Parsing delay
  static const Duration shortTimeout = Duration(seconds: 10);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration initialBackoff = Duration(milliseconds: 100);
  static const Duration maxBackoff = Duration(seconds: 2);

  // HTTP headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // API endpoints
  static const String turnEndpoint = '/v1/turns';
  static const String savesEndpoint = '/v1/saves';
  static const String manualSavesEndpoint = '/v1/saves/manual';
  static const String rollbackEndpoint = '/v1/rollback';
  static const String characterEndpoint = '/v1/character';
  static const String healthCheckEndpoint = '/health';

  // Error codes from backend
  static const String errorCodeClarificationRequired = 'CLARIFICATION_REQUIRED';
  static const String errorCodeConflict = 'CONFLICT';
  static const String errorCodeSafeReject = 'SAFE_REJECT';
  static const String errorCodeIdempotencyConflict =
      'IDEMPOTENCY_CONFLICT';

  // ============ INPUT VALIDATION LIMITS ============
  // Maximum length for action text (player input)
  static const int maxActionTextLength = 500;
  // Maximum length for clarification answers
  static const int maxClarificationAnswerLength = 200;
  // Minimum length for meaningful actions
  static const int minActionTextLength = 1;

  // ============ RATE LIMITING GUIDANCE ============
  // Backend enforces these limits; client validates for UX feedback
  static const int maxTurnsPerMinute = 4;
  static const int maxManualSavesPerRun = 20;
}

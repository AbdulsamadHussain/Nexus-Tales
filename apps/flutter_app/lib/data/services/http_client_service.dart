import 'package:dio/dio.dart';
import 'network_config.dart';
import 'network_exception.dart';
import 'http_client_interface.dart';

/// HTTP client service with interceptors, error handling, and retry logic
class HttpClientService implements HttpClientServiceInterface {
  late final Dio _dio;

  HttpClientService({String? baseUrl, String? authToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? NetworkConfig.baseUrl,
        connectTimeout: NetworkConfig.defaultTimeout,
        receiveTimeout: NetworkConfig.defaultTimeout,
        sendTimeout: NetworkConfig.defaultTimeout,
        headers: NetworkConfig.defaultHeaders,
      ),
    );

    // Add auth token if provided
    if (authToken != null && authToken.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $authToken';
    }

    // Add logging interceptor
    _dio.interceptors.add(_LoggingInterceptor());

    // Add error handling interceptor
    _dio.interceptors.add(_ErrorHandlingInterceptor());
  }

  /// Update auth token (e.g., after refresh)
  @override
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// POST request with automatic retry on transient errors
  @override
  Future<T> post<T>(
    String path, {
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    return _executeWithRetry<T>(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          sendTimeout: timeout ?? NetworkConfig.defaultTimeout,
          receiveTimeout: timeout ?? NetworkConfig.defaultTimeout,
        ),
      ),
    );
  }

  /// GET request with automatic retry
  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    return _executeWithRetry<T>(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(
          receiveTimeout: timeout ?? NetworkConfig.defaultTimeout,
        ),
      ),
    );
  }

  /// PUT request with automatic retry
  @override
  Future<T> put<T>(
    String path, {
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    return _executeWithRetry<T>(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          sendTimeout: timeout ?? NetworkConfig.defaultTimeout,
          receiveTimeout: timeout ?? NetworkConfig.defaultTimeout,
        ),
      ),
    );
  }

  /// DELETE request with automatic retry
  @override
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    return _executeWithRetry<T>(
      () => _dio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: Options(
          receiveTimeout: timeout ?? NetworkConfig.defaultTimeout,
        ),
      ),
    );
  }

  /// Execute request with retry logic for transient failures
  Future<T> _executeWithRetry<T>(
    Future<Response<T>> Function() request,
  ) async {
    int retries = 0;
    Duration backoff = NetworkConfig.initialBackoff;

    while (true) {
      try {
        final response = await request();
        final data = response.data;
        if (data != null) {
          return data;
        }
        throw UnknownNetworkException(
          message: 'Response data is null',
        );
      } on NetworkException catch (e) {
        if (!e.isRetryable || retries >= NetworkConfig.maxRetries) {
          rethrow;
        }

        // Exponential backoff with jitter
        await Future.delayed(backoff);
        backoff = Duration(
          milliseconds: (backoff.inMilliseconds * 1.5 +
                  (DateTime.now().millisecond % 100))
              .toInt(),
        );
        if (backoff > NetworkConfig.maxBackoff) {
          backoff = NetworkConfig.maxBackoff;
        }

        retries++;
      } catch (e) {
        // Wrap unexpected errors
        throw UnknownNetworkException(
          message: 'Unexpected error: $e',
          originalError: e,
        );
      }
    }
  }
}

/// Logging interceptor for all requests and responses
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Request logging can be implemented via debugLogRequest if needed
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Response logging can be implemented via debugLogResponse if needed
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Error logging can be implemented via debugLogError if needed
    handler.next(err);
  }
}

/// Error handling interceptor that converts Dio errors to NetworkException
class _ErrorHandlingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final networkException = _dioErrorToNetworkException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: networkException,
        type: err.type,
        response: err.response,
      ),
    );
  }

  NetworkException _dioErrorToNetworkException(DioException err) {
    if (err.error is NetworkException) {
      return err.error as NetworkException;
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutException(
          timeout: Duration(seconds: 30), // Extract from request options
          originalError: err,
          stackTrace: StackTrace.current,
        );

      case DioExceptionType.connectionError:
        // Check if it's no internet or other connection error
        if (err.message?.contains('Network is unreachable') ?? false) {
          return NoInternetException(
            originalError: err,
            stackTrace: StackTrace.current,
          );
        }
        return NoInternetException(
          message: err.message ?? 'Connection error',
          originalError: err,
          stackTrace: StackTrace.current,
        );

      case DioExceptionType.unknown:
        return UnknownNetworkException(
          message: err.message ?? 'Unknown error',
          originalError: err,
          stackTrace: StackTrace.current,
        );

      case DioExceptionType.badResponse:
        final response = err.response;
        if (response != null) {
          return _handleBadResponse(response);
        }
        return HttpException(
          statusCode: response?.statusCode ?? 0,
          message: err.message ?? 'HTTP error',
          originalError: err,
          stackTrace: StackTrace.current,
        );

      case DioExceptionType.cancel:
        return UnknownNetworkException(
          message: 'Request cancelled',
          originalError: err,
          stackTrace: StackTrace.current,
        );

      case DioExceptionType.badCertificate:
        return UnknownNetworkException(
          message: 'Bad certificate',
          originalError: err,
          stackTrace: StackTrace.current,
        );
    }
  }

  NetworkException _handleBadResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    final responseBody = response.data;

    // Handle special error codes from backend
    if (responseBody is Map<String, dynamic>) {
      final errorCode = responseBody['error_code'] as String?;
      final String errorMessage = switch (responseBody['message']) {
        String msg => msg,
        _ => '',
      };

      if (errorCode is String && errorCode == 'CLARIFICATION_REQUIRED') {
        return ClarificationRequiredException(
          prompt: responseBody['clarification_prompt'] ?? 'Please clarify',
          clientTurnIdForRetry: responseBody['client_turn_id'] ?? '',
          clarificationContext:
              responseBody['clarification_context'] ?? {},
          originalError: response,
        );
      }

      if (errorCode is String && errorCode == 'IDEMPOTENCY_CONFLICT') {
        return IdempotencyConflictException(
          clientTurnId: responseBody['client_turn_id'] ?? '',
          originalRequestHash:
              responseBody['original_request_hash'] ?? '',
          incomingRequestHash:
              responseBody['incoming_request_hash'] ?? '',
          message: errorMessage,
          originalError: response,
        );
      }

      if (errorCode is String && errorCode == 'SAFE_REJECT') {
        return SafeRejectException(
          errorCode: errorCode,
          message: errorMessage,
          context: responseBody['context'] ?? {},
          retryAllowed: responseBody['retry_allowed'] ?? false,
          originalError: response,
        );
      }

      if (errorCode is String && errorCode == 'CONFLICT') {
        return SafeRejectException(
          errorCode: 'CONFLICT',
          message: 'Action conflicts with server state. Please try again.',
          context: responseBody['conflict_context'] ?? {},
          retryAllowed: true,
          originalError: response,
        );
      }
    }

    // Generic HTTP error handling
    final message = switch (statusCode) {
      400 => 'Bad request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not found',
      429 => 'Too many requests',
      >= 500 => 'Server error',
      _ => 'HTTP error: $statusCode',
    };

    return HttpException(
      statusCode: statusCode,
      message: message,
      responseBody: responseBody,
      originalError: response,
    );
  }
}

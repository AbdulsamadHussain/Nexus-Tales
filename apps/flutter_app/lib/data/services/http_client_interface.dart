/// Abstract interface for HTTP client service
/// Allows swapping between real HttpClientService and MockHttpClientService
abstract class HttpClientServiceInterface {
  /// GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  });

  /// POST request
  Future<T> post<T>(
    String path, {
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  });

  /// PUT request
  Future<T> put<T>(
    String path, {
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  });

  /// DELETE request
  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  });

  /// Update auth token
  void setAuthToken(String token);
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/mock_http_client.dart';

part 'auth_provider.g.dart';

/// Provides authentication token
/// During Phase 2: Returns mock token
/// After backend auth ready: Fetch real token from /v1/auth/login
@riverpod
Future<String> authToken(AuthTokenRef ref) async {
  // Phase 2: Mock authentication
  return MockHttpClientService.getMockAuthToken();

  // TODO: When backend auth is ready, uncomment:
  // final httpClient = ref.watch(httpClientProvider);
  // final response = await httpClient.post<Map<String, dynamic>>(
  //   '/v1/auth/login',
  //   data: {
  //     'credentials': {...}, // Your actual auth mechanism
  //   },
  // );
  // return response['token'] as String;
}

/// Synchronous accessor for auth token (for use in interceptors)
/// Returns mock token immediately; real token would be cached/retrieved synchronously
@riverpod
String authTokenSync(AuthTokenSyncRef ref) {
  // Phase 2: Return mock token directly
  // In production, this would be retrieved from secure storage
  return MockHttpClientService.getMockAuthToken();
}

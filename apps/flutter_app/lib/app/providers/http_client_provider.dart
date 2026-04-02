import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/services/http_client_interface.dart';
import '../../data/services/http_client_service.dart';
import '../../data/repositories/mock_http_client.dart';
import 'auth_provider.dart';

part 'http_client_provider.g.dart';

/// Toggle between mock and real HTTP client
/// Set to false when backend auth is implemented
const bool useMockHttp = true;

/// Provides HTTP client service (mock during Phase 2, real after backend ready)
/// Mock client simulates API responses with realistic delays
/// Real client connects to actual backend with JWT authentication
@riverpod
HttpClientServiceInterface httpClient(HttpClientRef ref) {
  final authToken = ref.watch(authTokenSyncProvider);

  if (useMockHttp) {
    return MockHttpClientService();
  } else {
    return HttpClientService(authToken: authToken);
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$httpClientHash() => r'53a575d36ea1cb1a4381b91cff755862304656ab';

/// Provides HTTP client service (mock during Phase 2, real after backend ready)
/// Mock client simulates API responses with realistic delays
/// Real client connects to actual backend with JWT authentication
///
/// Copied from [httpClient].
@ProviderFor(httpClient)
final httpClientProvider =
    AutoDisposeProvider<HttpClientServiceInterface>.internal(
  httpClient,
  name: r'httpClientProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$httpClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HttpClientRef = AutoDisposeProviderRef<HttpClientServiceInterface>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

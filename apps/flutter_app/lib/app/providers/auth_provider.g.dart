// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authTokenHash() => r'67821734aa4eafa80049c61019a107b8848a6a81';

/// Provides authentication token
/// During Phase 2: Returns mock token
/// After backend auth ready: Fetch real token from /v1/auth/login
///
/// Copied from [authToken].
@ProviderFor(authToken)
final authTokenProvider = AutoDisposeFutureProvider<String>.internal(
  authToken,
  name: r'authTokenProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authTokenHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthTokenRef = AutoDisposeFutureProviderRef<String>;
String _$authTokenSyncHash() => r'4e16e8a1d249f8a43659b42da0956a79b5e2a057';

/// Synchronous accessor for auth token (for use in interceptors)
/// Returns mock token immediately; real token would be cached/retrieved synchronously
///
/// Copied from [authTokenSync].
@ProviderFor(authTokenSync)
final authTokenSyncProvider = AutoDisposeProvider<String>.internal(
  authTokenSync,
  name: r'authTokenSyncProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authTokenSyncHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthTokenSyncRef = AutoDisposeProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hydration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hydrationHash() => r'fa73dcaea3ce26253543746dcd7d8962389e490d';

/// Loads initial game state on app startup
/// Fetches character, quests, inventory, codex, factions, relationships, and scene
/// Updates all corresponding state providers with authoritative data
/// Failure to hydrate leaves state empty and shows error to user
///
/// Copied from [hydration].
@ProviderFor(hydration)
final hydrationProvider = AutoDisposeFutureProvider<HydrationStatus>.internal(
  hydration,
  name: r'hydrationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$hydrationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HydrationRef = AutoDisposeFutureProviderRef<HydrationStatus>;
String _$isHydratedHash() => r'31bec9fd47a885c37573056e289558f4f42bbc6c';

/// Computed provider: Is app hydrated?
/// Returns true only when hydration has completed successfully
///
/// Copied from [isHydrated].
@ProviderFor(isHydrated)
final isHydratedProvider = AutoDisposeProvider<bool>.internal(
  isHydrated,
  name: r'isHydratedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isHydratedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsHydratedRef = AutoDisposeProviderRef<bool>;
String _$isHydratingHash() => r'65733006b6da6457e1fad56e173d8ee2b3dd67da';

/// Computed provider: Is hydration in progress?
/// Use for showing loading screen/splash
///
/// Copied from [isHydrating].
@ProviderFor(isHydrating)
final isHydratingProvider = AutoDisposeProvider<bool>.internal(
  isHydrating,
  name: r'isHydratingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isHydratingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsHydratingRef = AutoDisposeProviderRef<bool>;
String _$hydrationErrorHash() => r'e14401e50105c041024bb6118096433077bca6b2';

/// Computed provider: Hydration error message
/// Returns error message if hydration failed, null if successful or loading
///
/// Copied from [hydrationError].
@ProviderFor(hydrationError)
final hydrationErrorProvider = AutoDisposeProvider<String?>.internal(
  hydrationError,
  name: r'hydrationErrorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hydrationErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HydrationErrorRef = AutoDisposeProviderRef<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$turnRepositoryHash() => r'37dc868ae4134e07c947b3e44dea6512866f8a88';

/// Provides TurnRepository for submitting turn actions
///
/// Copied from [turnRepository].
@ProviderFor(turnRepository)
final turnRepositoryProvider = AutoDisposeProvider<TurnRepository>.internal(
  turnRepository,
  name: r'turnRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$turnRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TurnRepositoryRef = AutoDisposeProviderRef<TurnRepository>;
String _$saveRepositoryHash() => r'c0c404d7877c056e1edc96159b36346e0ebb6475';

/// Provides SaveRepository for creating, loading, and deleting saves
///
/// Copied from [saveRepository].
@ProviderFor(saveRepository)
final saveRepositoryProvider = AutoDisposeProvider<SaveRepository>.internal(
  saveRepository,
  name: r'saveRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$saveRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SaveRepositoryRef = AutoDisposeProviderRef<SaveRepository>;
String _$rollbackRepositoryHash() =>
    r'1b833add1de5258625ca05ec210a4888d2f2bf58';

/// Provides RollbackRepository for rolling back to previous revisions
///
/// Copied from [rollbackRepository].
@ProviderFor(rollbackRepository)
final rollbackRepositoryProvider =
    AutoDisposeProvider<RollbackRepository>.internal(
  rollbackRepository,
  name: r'rollbackRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$rollbackRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RollbackRepositoryRef = AutoDisposeProviderRef<RollbackRepository>;
String _$characterRepositoryHash() =>
    r'd1f1c7ddd50524099f01a8807e9ca9716b13912f';

/// Provides CharacterRepository for loading character and related data
///
/// Copied from [characterRepository].
@ProviderFor(characterRepository)
final characterRepositoryProvider =
    AutoDisposeProvider<CharacterRepository>.internal(
  characterRepository,
  name: r'characterRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$characterRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CharacterRepositoryRef = AutoDisposeProviderRef<CharacterRepository>;
String _$submitTurnHash() => r'f33a760af9995539f32651ec206c0705ef104062';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Submits a turn action to the backend and returns the result
/// Used by play_screen to send player actions to the server
///
/// Usage:
/// ```dart
/// final result = await ref.read(
///   submitTurnProvider((
///     action: 'attack the goblin',
///     runId: 'run-123',
///     saveSlotId: 'slot-456',
///   )).future,
/// );
/// ```
///
/// Copied from [submitTurn].
@ProviderFor(submitTurn)
const submitTurnProvider = SubmitTurnFamily();

/// Submits a turn action to the backend and returns the result
/// Used by play_screen to send player actions to the server
///
/// Usage:
/// ```dart
/// final result = await ref.read(
///   submitTurnProvider((
///     action: 'attack the goblin',
///     runId: 'run-123',
///     saveSlotId: 'slot-456',
///   )).future,
/// );
/// ```
///
/// Copied from [submitTurn].
class SubmitTurnFamily extends Family<AsyncValue<TurnResult>> {
  /// Submits a turn action to the backend and returns the result
  /// Used by play_screen to send player actions to the server
  ///
  /// Usage:
  /// ```dart
  /// final result = await ref.read(
  ///   submitTurnProvider((
  ///     action: 'attack the goblin',
  ///     runId: 'run-123',
  ///     saveSlotId: 'slot-456',
  ///   )).future,
  /// );
  /// ```
  ///
  /// Copied from [submitTurn].
  const SubmitTurnFamily();

  /// Submits a turn action to the backend and returns the result
  /// Used by play_screen to send player actions to the server
  ///
  /// Usage:
  /// ```dart
  /// final result = await ref.read(
  ///   submitTurnProvider((
  ///     action: 'attack the goblin',
  ///     runId: 'run-123',
  ///     saveSlotId: 'slot-456',
  ///   )).future,
  /// );
  /// ```
  ///
  /// Copied from [submitTurn].
  SubmitTurnProvider call({
    required String action,
    required String runId,
    required String saveSlotId,
  }) {
    return SubmitTurnProvider(
      action: action,
      runId: runId,
      saveSlotId: saveSlotId,
    );
  }

  @override
  SubmitTurnProvider getProviderOverride(
    covariant SubmitTurnProvider provider,
  ) {
    return call(
      action: provider.action,
      runId: provider.runId,
      saveSlotId: provider.saveSlotId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'submitTurnProvider';
}

/// Submits a turn action to the backend and returns the result
/// Used by play_screen to send player actions to the server
///
/// Usage:
/// ```dart
/// final result = await ref.read(
///   submitTurnProvider((
///     action: 'attack the goblin',
///     runId: 'run-123',
///     saveSlotId: 'slot-456',
///   )).future,
/// );
/// ```
///
/// Copied from [submitTurn].
class SubmitTurnProvider extends AutoDisposeFutureProvider<TurnResult> {
  /// Submits a turn action to the backend and returns the result
  /// Used by play_screen to send player actions to the server
  ///
  /// Usage:
  /// ```dart
  /// final result = await ref.read(
  ///   submitTurnProvider((
  ///     action: 'attack the goblin',
  ///     runId: 'run-123',
  ///     saveSlotId: 'slot-456',
  ///   )).future,
  /// );
  /// ```
  ///
  /// Copied from [submitTurn].
  SubmitTurnProvider({
    required String action,
    required String runId,
    required String saveSlotId,
  }) : this._internal(
          (ref) => submitTurn(
            ref as SubmitTurnRef,
            action: action,
            runId: runId,
            saveSlotId: saveSlotId,
          ),
          from: submitTurnProvider,
          name: r'submitTurnProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$submitTurnHash,
          dependencies: SubmitTurnFamily._dependencies,
          allTransitiveDependencies:
              SubmitTurnFamily._allTransitiveDependencies,
          action: action,
          runId: runId,
          saveSlotId: saveSlotId,
        );

  SubmitTurnProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.action,
    required this.runId,
    required this.saveSlotId,
  }) : super.internal();

  final String action;
  final String runId;
  final String saveSlotId;

  @override
  Override overrideWith(
    FutureOr<TurnResult> Function(SubmitTurnRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubmitTurnProvider._internal(
        (ref) => create(ref as SubmitTurnRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        action: action,
        runId: runId,
        saveSlotId: saveSlotId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TurnResult> createElement() {
    return _SubmitTurnProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubmitTurnProvider &&
        other.action == action &&
        other.runId == runId &&
        other.saveSlotId == saveSlotId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, action.hashCode);
    hash = _SystemHash.combine(hash, runId.hashCode);
    hash = _SystemHash.combine(hash, saveSlotId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SubmitTurnRef on AutoDisposeFutureProviderRef<TurnResult> {
  /// The parameter `action` of this provider.
  String get action;

  /// The parameter `runId` of this provider.
  String get runId;

  /// The parameter `saveSlotId` of this provider.
  String get saveSlotId;
}

class _SubmitTurnProviderElement
    extends AutoDisposeFutureProviderElement<TurnResult> with SubmitTurnRef {
  _SubmitTurnProviderElement(super.provider);

  @override
  String get action => (origin as SubmitTurnProvider).action;
  @override
  String get runId => (origin as SubmitTurnProvider).runId;
  @override
  String get saveSlotId => (origin as SubmitTurnProvider).saveSlotId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

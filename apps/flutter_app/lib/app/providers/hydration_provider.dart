import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/game_models.dart';
import 'repository_providers.dart';
import '../routing/riverpod_providers.dart';

part 'hydration_provider.g.dart';

/// Hydration status - tracks whether initial game state has been loaded
enum HydrationStatus { loading, success, failure }

/// Loads initial game state on app startup
/// Fetches character, quests, inventory, codex, factions, relationships, and scene
/// Updates all corresponding state providers with authoritative data
/// Failure to hydrate leaves state empty and shows error to user
@riverpod
Future<HydrationStatus> hydration(HydrationRef ref) async {
  try {
    const runId = 'run-001';
    const saveSlotId = 'slot-001';

    // Fetch all authoritative state in parallel where possible
    final character = await ref
        .watch(characterRepositoryProvider)
        .fetchCharacter(runId, saveSlotId);
    final quests =
        await ref.watch(characterRepositoryProvider).fetchQuests(runId);
    final inventory = await ref
        .watch(characterRepositoryProvider)
        .fetchInventory(runId);
    final codexEntries = await ref
        .watch(characterRepositoryProvider)
        .fetchCodexEntries(runId);
    final factions =
        await ref.watch(characterRepositoryProvider).fetchFactions(runId);
    final relationships = await ref
        .watch(characterRepositoryProvider)
        .fetchRelationships(runId);

    // Update all state providers with fetched data
    ref.read(currentCharacterProvider.notifier).state = character;
    ref.read(questListProvider.notifier).state = quests;
    ref.read(inventoryProvider.notifier).state = inventory;
    ref.read(codexEntriesProvider.notifier).state = codexEntries;
    ref.read(factionsProvider.notifier).state = factions;
    ref.read(relationshipsProvider.notifier).state = relationships;

    // Set initial scene
    ref.read(currentSceneProvider.notifier).state = Scene(
      id: 'scene-001',
      title: 'Starting Location',
      description: 'A peaceful forest clearing with dappled sunlight.',
      controllingFaction: 'neutral',
      dangerLevel: 'safe',
    );

    return HydrationStatus.success;
  } on Exception {
    // Avoid print in production - use proper logging
    return HydrationStatus.failure;
  }
}

/// Computed provider: Is app hydrated?
/// Returns true only when hydration has completed successfully
@riverpod
bool isHydrated(IsHydratedRef ref) {
  final hydrationAsync = ref.watch(hydrationProvider);
  return hydrationAsync.when(
    data: (status) => status == HydrationStatus.success,
    error: (_, __) => false,
    loading: () => false,
  );
}

/// Computed provider: Is hydration in progress?
/// Use for showing loading screen/splash
@riverpod
bool isHydrating(IsHydratingRef ref) {
  final hydrationAsync = ref.watch(hydrationProvider);
  return hydrationAsync.isLoading;
}

/// Computed provider: Hydration error message
/// Returns error message if hydration failed, null if successful or loading
@riverpod
String? hydrationError(HydrationErrorRef ref) {
  final hydrationAsync = ref.watch(hydrationProvider);
  return hydrationAsync.when(
    data: (status) => status == HydrationStatus.failure
        ? 'Failed to load game state. Please check your connection and try again.'
        : null,
    error: (err, __) => 'Unexpected error during load: $err',
    loading: () => null,
  );
}

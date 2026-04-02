# Phase 5: Backend Integration Implementation Plan

**Objective**: Wire Flutter UI to Node/Fastify backend, implement full turn lifecycle, and achieve Phase 5 exit gate: "A player can complete the full loop from input to authoritative result to save/load/rollback without any client-side invention of canonical state."

**Timeline**: 100-135 hours (4-6 weeks at 25 hrs/week sustained)

**Prerequisites**:
- Backend contracts package is locked and OpenAPI is generated
- `/v1/turns`, `/v1/saves/manual`, `/v1/saves`, `/v1/rollback` endpoints exist
- PostgreSQL advisory lock serialization is implemented
- Revision model and outbox workers are in place

---

## Milestone 1: HTTP Client & Repository Foundation (40-50 hours)

### Phase 1.1: Network Layer Setup (8-10 hours)

**Deliverables**:
- [ ] HTTP client service with interceptors
- [ ] Error handling and retry logic
- [ ] Auth token injection
- [ ] Request/response logging

**Files to Create**:
```
lib/data/services/
  ├── http_client_service.dart          (Dio setup, interceptors, error handling)
  ├── network_exception.dart             (Custom exceptions)
  └── network_config.dart                (Base URLs, timeouts, headers)
```

**Implementation Details**:
- Use `dio` package with interceptors for logging and auth
- Implement `NetworkException` with retry-able vs fatal discrimination
- Add device fingerprinting / session tracking for idempotency
- Timeout: 30s for normal requests, 60s for turn submission (parsing delay)
- Backoff strategy: exponential with jitter (100ms-2s)
- Max retries: 3 for idempotent ops, 0 for mutating ops initially

**Exit Criteria**:
- HTTP client initializes without crashes
- Interceptors log all requests/responses
- Auth token is injected into headers
- Error classification is deterministic

---

### Phase 1.2: Data Transfer Objects (DTOs) (10-15 hours)

**Deliverables**:
- [ ] Turn request/response DTOs
- [ ] Save slot & checkpoint DTOs
- [ ] Character state DTOs
- [ ] Rollback request/response DTOs
- [ ] All DTOs with `@JsonSerializable()`

**Files to Create**:
```
lib/data/dto/
  ├── turn_dto.dart                      (TurnRequest, TurnAuthoritativeResponse)
  ├── turn_result_dto.dart               (SimulationResult, CanonicalEvent)
  ├── save_slot_dto.dart                 (SaveSnapshot, SaveMetadata)
  ├── character_state_dto.dart           (Character, InventoryItem, Quest, etc.)
  ├── rollback_dto.dart                  (RollbackRequest, RollbackResponse)
  ├── clarification_dto.dart             (ClarificationPrompt, ClarificationAnswer)
  ├── common_dto.dart                    (shared enums, base responses)
  └── dto_index.dart                     (re-exports for clean imports)
```

**Key DTO Structures**:

**TurnRequest**:
```dart
{
  "client_turn_id": "uuid",              // Idempotency key (client-generated)
  "run_id": "uuid",
  "save_slot_id": "uuid",
  "action": "string",
  "scene_fingerprint": "string",         // For ambiguity/clarification tracking
  "schema_version": "int"
}
```

**TurnAuthoritativeResponse**:
```dart
{
  "status": "ACCEPTED|CLARIFICATION_REQUIRED|SAFE_REJECT|CONFLICT",
  "revision_id": "uuid",                 // Only if ACCEPTED
  "request_hash": "string",              // For conflict detection
  "simulation_result": {
    "action_outcome": "SUCCESS|PARTIAL|FAILURE",
    "roll_result": {...},
    "consequences": [...],
    "canonical_events": [...]
  },
  "character_state_delta": {...},        // HP, stamina, inventory changes
  "autosave_eligible": bool,
  "clarification_prompt": "string",      // If CLARIFICATION_REQUIRED
  "clarification_context": {...},
  "conflict_original_hash": "string",    // If CONFLICT
  "error_message": "string"              // If SAFE_REJECT
}
```

**SaveSnapshot**:
```dart
{
  "save_slot_id": "uuid",
  "manual_save_id": "uuid",
  "revision_id": "uuid",
  "timestamp": "iso8601",
  "location": "string",
  "chapter_number": "int",
  "quest_milestone": "string",
  "character_snapshot": {...},
  "game_state_snapshot": {...},
  "schema_version": "int"
}
```

**Implementation Notes**:
- Use `@JsonSerializable()` with `explicitToJson: true` for nested serialization
- Generate with `dart run build_runner build`
- Add custom `fromJson` factories for enum/DateTime edge cases
- Keep DTOs nullable-by-default; schema constrains at API boundary

**Exit Criteria**:
- All DTOs match backend schema (verify against OpenAPI)
- JSON serialization/deserialization round-trips without loss
- Enum serialization matches backend (snake_case or camelCase consistency)
- build_runner produces no errors

---

### Phase 1.3: Mapper Functions (5-8 hours)

**Deliverables**:
- [ ] DTO ↔ Domain model mappers
- [ ] Collection mappers (list/sets)
- [ ] Null-safety aware mappings

**Files to Create**:
```
lib/data/mappers/
  ├── turn_mapper.dart
  ├── character_mapper.dart
  ├── save_mapper.dart
  ├── quest_mapper.dart
  ├── inventory_mapper.dart
  ├── codex_mapper.dart
  ├── faction_mapper.dart
  └── mapper_utils.dart                  (shared mapping helpers)
```

**Key Mappings**:
- `TurnAuthoritativeResponseDTO` → `TurnResult` (domain model)
- `CharacterStateDTO` → `PlayerCharacter` (domain model)
- `SaveSnapshotDTO` → `SaveSlot` (domain model)
- `CanonicalEventDTO` → custom event rendering models

**Implementation Notes**:
- Handle nullable fields gracefully (use fallback defaults for non-authoritative fields)
- Map enums bidirectionally (API strings ↔ domain enums)
- Create null-aware collection mappers for lists/maps
- Add logging for mapping failures (for debugging deserialization issues)

**Exit Criteria**:
- Domain models are never instantiated from raw JSON (always via mappers)
- Mappers are testable in isolation
- No null reference exceptions from unexpected JSON shapes

---

### Phase 1.4: Repository Interfaces & Implementation (15-20 hours)

**Deliverables**:
- [ ] TurnRepository (POST /v1/turns)
- [ ] SaveRepository (POST/GET /v1/saves)
- [ ] RollbackRepository (POST /v1/rollback)
- [ ] CharacterRepository (GET /v1/character)
- [ ] StateHydrationRepository (multi-endpoint fetch)

**Files to Create**:
```
lib/data/repositories/
  ├── turn_repository.dart               (interface + implementation)
  ├── save_repository.dart               (interface + implementation)
  ├── rollback_repository.dart           (interface + implementation)
  ├── character_repository.dart          (interface + implementation)
  ├── state_hydration_repository.dart    (interface + implementation)
  └── repository_index.dart              (re-exports + DI setup)
```

**TurnRepository Contract**:
```dart
abstract class TurnRepository {
  /// Submit a turn action.
  /// Throws [IdempotencyConflictException] if same key, different payload.
  /// Throws [ClarificationRequiredException] if clarification needed.
  /// Throws [SafeRejectException] if policy rejected.
  /// Throws [NetworkException] on network failure.
  Future<TurnResult> submitTurn(TurnRequest request);
}
```

**SaveRepository Contract**:
```dart
abstract class SaveRepository {
  /// Create a manual save.
  /// Throws [SaveSlotExhaustedException] if no slots available.
  /// Throws [NetworkException] on network failure.
  Future<SaveSlot> createManualSave(SaveRequest request);

  /// Fetch all saves for current run.
  Future<SaveSlots> fetchSaves(String runId, String saveSlotId);

  /// Delete a manual save.
  Future<void> deleteManualSave(String saveId);
}
```

**RollbackRepository Contract**:
```dart
abstract class RollbackRepository {
  /// Rollback to a specific revision.
  /// Throws [RollbackForbiddenException] if revision is not rollback-safe.
  /// Throws [NetworkException] on network failure.
  Future<RestoredGameState> rollbackToRevision(String revisionId);

  /// Rollback to a checkpoint.
  Future<RestoredGameState> rollbackToCheckpoint(String checkpointId);
}
```

**CharacterRepository Contract**:
```dart
abstract class CharacterRepository {
  /// Hydrate character on app launch.
  Future<PlayerCharacter> fetchCharacter(String runId);

  /// Fetch quests with current progress.
  Future<List<Quest>> fetchQuests(String runId);

  /// Fetch inventory.
  Future<List<InventoryItem>> fetchInventory(String runId);

  /// Fetch codex entries (discovered only).
  Future<List<CodexEntry>> fetchCodexEntries(String runId);

  /// Fetch faction standings.
  Future<List<Faction>> fetchFactions(String runId);

  /// Fetch relationships.
  Future<List<Relationship>> fetchRelationships(String runId);
}
```

**StateHydrationRepository Contract**:
```dart
abstract class StateHydrationRepository {
  /// Parallel fetch of all authoritative remote state on app launch.
  /// Returns complete game state or null if session invalid.
  Future<GameState?> hydrateFromCheckpoint(String runId, String saveSlotId);
}
```

**Implementation Notes**:
- Inject HTTP client into repositories
- Use mappers to convert DTO → domain at repository boundary
- For idempotency: track `client_turn_id` locally; if resubmit same ID, check response hash
- For conflicts: parse `request_hash` mismatch, throw `IdempotencyConflictException`
- For clarification: throw exception that includes prompt and context
- All repositories should log request/response at debug level

**Exit Criteria**:
- All repository methods are testable (can mock HTTP client)
- Error cases are explicitly typed (no generic Exception)
- Mappers are called at repo boundary (no raw JSON in domain layer)
- Timeout/retry logic is consistent across all repos

---

## Milestone 2: Riverpod Provider Wiring (15-20 hours)

### Phase 2.1: Hydration & Initial State Load (6-8 hours)

**Deliverables**:
- [ ] Hydration provider that loads on app startup
- [ ] Error handling for hydration failures
- [ ] Retry logic for transient network errors
- [ ] Offline-first fallback to local cache

**Files to Modify**:
```
lib/app/routing/riverpod_providers.dart  (add/update)
  ├── hydrationProvider               (FutureProvider)
  ├── gameStateProvider               (StateNotifierProvider, depends on hydration)
  ├── currentCharacterProvider        (computed from game state)
  ├── currentQuestsProvider           (computed from game state)
  └── etc. (all 28 providers update to read from hydration)
```

**Implementation Pattern**:
```dart
final hydrationProvider = FutureProvider<GameState?>(
  (ref) async {
    // On startup:
    // 1. Check local cache (if exists and recent)
    // 2. Attempt network hydration
    // 3. If network fails, fall back to local cache
    // 4. If no cache, return null (show empty state)
    
    try {
      final state = await ref.read(stateHydrationRepositoryProvider)
          .hydrateFromCheckpoint(runId, saveSlotId);
      return state;
    } on NetworkException {
      // Fall back to local cache
      return ref.read(localCacheProvider).getGameState();
    }
  }
);
```

**Exit Criteria**:
- On app launch, all 28 providers load state from network or local cache
- Network errors don't crash the app
- Loading state is visible in UI
- Retry mechanism is non-blocking

---

### Phase 2.2: Turn Submission & Result Synchronization (5-8 hours)

**Deliverables**:
- [ ] TurnSubmissionProvider that accepts action + returns result
- [ ] Synchronization of canonical state from turn result
- [ ] Update to all dependent providers post-turn
- [ ] Optimistic UI updates (optional, risky)

**Files to Modify**:
```
lib/app/routing/riverpod_providers.dart  (add)
  ├── turnSubmissionProvider          (FutureProvider with submit logic)
  └── All 28 dependent providers updated to read from turn result
```

**Implementation Pattern**:
```dart
// Triggered when player submits action
Future<void> submitTurn(WidgetRef ref, String action) async {
  try {
    ref.read(isSubmittingProvider.notifier).state = true;
    
    final result = await ref.read(turnRepositoryProvider)
        .submitTurn(TurnRequest(...));
    
    // Synchronize ALL authoritative state from turn result
    ref.read(currentCharacterProvider.notifier).state = 
      result.characterStateDelta;  // Apply delta to current character
    
    // Update quests if provided
    if (result.questUpdates != null) {
      ref.read(currentQuestsProvider.notifier).state = 
        result.questUpdates;
    }
    
    // Add turn to narrative history
    ref.read(storyCardsProvider.notifier).state = [
      ...ref.read(storyCardsProvider),
      ...result.canonicalEvents.map((e) => storyCard(e))
    ];
    
    // Reset draft state
    ref.read(draftActionProvider.notifier).state = '';
    
  } on ClarificationRequiredException catch (e) {
    // Show clarification modal
    ref.read(clarificationPromptProvider.notifier).state = e.prompt;
  } on IdempotencyConflictException catch (e) {
    // Log conflict, show user error
    ref.read(errorMessageProvider.notifier).state = 
      'Action conflict detected. Please try again.';
  } finally {
    ref.read(isSubmittingProvider.notifier).state = false;
  }
}
```

**Exit Criteria**:
- Turn submission updates character HP, stamina, mana correctly
- Quest progress updates reflect simulation result
- Inventory changes are rendered immediately
- Draft action is cleared after successful submission

---

### Phase 2.3: Save/Load/Rollback Providers (4-6 hours)

**Deliverables**:
- [ ] SaveSlotProvider that lists all saves
- [ ] CreateManualSaveProvider
- [ ] LoadSaveProvider that restores full state
- [ ] RollbackProvider that calls backend and restores state

**Files to Modify**:
```
lib/app/routing/riverpod_providers.dart  (add)
  ├── saveHistoryProvider            (FutureProvider)
  ├── createSaveProvider             (async callback)
  ├── loadSaveProvider               (async callback, updates all state)
  └── rollbackProvider               (async callback, updates all state)
```

**Implementation Pattern**:
```dart
final createSaveProvider = FutureProvider.family<void, SaveRequest>(
  (ref, request) async {
    await ref.read(saveRepositoryProvider).createManualSave(request);
    // Invalidate save history to refresh
    ref.invalidate(saveHistoryProvider);
  }
);

final loadSaveProvider = FutureProvider.family<void, SaveSlot>(
  (ref, saveSlot) async {
    // Backend returns restored game state
    final restoredState = await ref.read(saveRepositoryProvider)
        .loadSave(saveSlot.id);
    
    // Synchronize ALL providers with restored state
    ref.read(currentCharacterProvider.notifier).state = 
      restoredState.character;
    ref.read(currentQuestsProvider.notifier).state = 
      restoredState.quests;
    // ... all 28 providers
    
    // Clear narrative history (start fresh from this checkpoint)
    ref.read(storyCardsProvider.notifier).state = [];
  }
);
```

**Exit Criteria**:
- Save creation works and refreshes save list
- Load restores full character, quests, inventory, relationships
- Rollback API call succeeds and state is restored
- All 28 providers are synchronized post-load/rollback

---

## Milestone 3: Gameplay Loop Integration (20-30 hours)

### Phase 3.1: Turn Submission UI Wiring (8-10 hours)

**Deliverables**:
- [ ] Replace mock `Future.delayed()` with real API call in PlayScreen
- [ ] Wire action input → turn submission
- [ ] Show loading state during submission
- [ ] Display canonical event results

**Files to Modify**:
```
lib/features/play/play_screen.dart
  └── _submitAction() method
```

**Current Mock Code** (from your file):
```dart
Future<void> _submitAction() async {
  if (draftAction.isEmpty) return;
  
  // Mock: delay only
  await Future.delayed(const Duration(seconds: 2));
  
  // Mock: add fake card
  final newCard = StoryCard(...)
  setState(() { storyCards.add(newCard); });
}
```

**Target Real Implementation**:
```dart
Future<void> _submitAction(WidgetRef ref) async {
  if (draftAction.isEmpty) return;
  
  final turnRequest = TurnRequest(
    clientTurnId: generateUUID(),  // Idempotency key
    runId: ref.read(currentRunIdProvider),
    saveSlotId: ref.read(currentSaveSlotIdProvider),
    action: draftAction,
    sceneFingerprint: ref.read(currentSceneProvider).fingerprint,
  );
  
  try {
    ref.read(isSubmittingProvider.notifier).state = true;
    
    final turnResult = await ref.read(turnRepositoryProvider)
        .submitTurn(turnRequest);
    
    // Render canonical events from result
    final eventCards = turnResult.canonicalEvents
        .map((e) => _buildEventCard(e))
        .toList();
    
    ref.read(storyCardsProvider.notifier).update(
      (cards) => [...cards, ...eventCards]
    );
    
    // Update character state
    ref.read(currentCharacterProvider.notifier).update(
      (character) => character.applyDelta(turnResult.characterStateDelta)
    );
    
    // Clear input
    ref.read(draftActionProvider.notifier).state = '';
    
  } on ClarificationRequiredException catch (e) {
    _showClarificationModal(e.prompt, e.context);
  } on IdempotencyConflictException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action conflict: ${e.message}'))
    );
  } on NetworkException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connection error. Retrying...'))
    );
    // Retry once more before giving up
  } finally {
    ref.read(isSubmittingProvider.notifier).state = false;
  }
}
```

**Implementation Notes**:
- Generate `client_turn_id` using `uuid` package (deterministic for same input)
- Use scene fingerprint from current scene (tracks ambiguity context)
- Show loading skeleton during 3-5s API roundtrip + parsing
- Parse `TurnAuthoritativeResponse` and map to `TurnResult`
- Render events as sequential story cards in narrative panel

**Exit Criteria**:
- Real turn submission works (API responds)
- Canonical events are rendered in order
- Character state updates are visible
- Draft action clears after success

---

### Phase 3.2: Clarification Flow Implementation (8-12 hours)

**Deliverables**:
- [ ] Clarification modal/dialog
- [ ] Clarification answer submission
- [ ] Ambiguity counter tracking
- [ ] Three-strike fallback to no-op

**Files to Create**:
```
lib/features/play/clarification/
  ├── clarification_modal.dart           (Modal UI)
  └── clarification_provider.dart        (State management)

lib/data/local_cache/
  ├── ambiguity_counter_cache.dart       (Track 3 attempts per scene)
```

**Implementation Pattern**:

**ClarificationModal**:
```dart
class ClarificationModal extends ConsumerWidget {
  final String prompt;
  final Map<String, dynamic> context;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Column(
        children: [
          Text('The story needs clarification:'),
          Text(prompt),
          TextField(
            onChanged: (value) => 
              ref.read(clarificationAnswerProvider.notifier).state = value,
          ),
          ElevatedButton(
            onPressed: () => _submitClarification(ref),
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _submitClarification(WidgetRef ref) async {
    final answer = ref.read(clarificationAnswerProvider);
    
    try {
      // Re-submit turn with clarification answer included
      final turnResult = await ref.read(turnRepositoryProvider)
          .submitTurnWithClarification(
            previousClientTurnId: ref.read(previousClientTurnIdProvider),
            clarificationAnswer: answer,
          );
      
      // Same as successful turn: add events, update state
      // ...
      
    } on ClarificationRequiredException {
      // Still ambiguous - increment counter
      ref.read(ambiguityCounterProvider.notifier).increment();
      
      if (ref.read(ambiguityCounterProvider) >= 3) {
        // Give up - return no-op
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action was unclear. Please try again.'))
        );
      }
      // else: show new clarification modal
    }
  }
}
```

**AmbiguityCounterProvider**:
```dart
final ambiguityCounterProvider = StateNotifierProvider<
  AmbiguityCounterNotifier, int>((ref) {
  return AmbiguityCounterNotifier(
    ref.watch(currentSceneProvider),
    ref.watch(localCacheProvider),
  );
});

class AmbiguityCounterNotifier extends StateNotifier<int> {
  AmbiguityCounterNotifier(Scene scene, LocalCache cache)
    : super(cache.getAmbiguityCount(scene.fingerprint) ?? 0);
  
  void increment() {
    state++;
    cache.setAmbiguityCount(sceneFingerprint, state);
  }
  
  void reset() {
    state = 0;
  }
}
```

**Exit Criteria**:
- Clarification modal shows when API returns `CLARIFICATION_REQUIRED`
- Answer resubmission works
- Ambiguity counter tracks up to 3 attempts
- Three-strike on same scene results in no-op

---

### Phase 3.3: Safe Reject & Policy Error Handling (4-8 hours)

**Deliverables**:
- [ ] SAFE_REJECT error display
- [ ] Policy-blocked action messaging
- [ ] Retry vs give-up decisions
- [ ] Graceful degradation

**Files to Create**:
```
lib/features/play/errors/
  └── error_display_widget.dart          (Show policy rejections)
```

**Implementation Pattern**:
```dart
// In PlayScreen._submitAction()
catch (SafeRejectException e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Action cannot proceed:'),
          Text(e.playerMessage),  // Backend-safe message
          if (e.retryAllowed)
            ElevatedButton(
              onPressed: () => _submitAction(ref),
              child: Text('Try again'),
            ),
        ],
      ),
      backgroundColor: Colors.red[900],
    ),
  );
}
```

**Exit Criteria**:
- SAFE_REJECT errors show appropriate user message
- Policy violations don't crash app
- Retry logic respects backend retry_allowed flag

---

## Milestone 4: Save/Load/Rollback Management (15-20 hours)

### Phase 4.1: Save/Load Screen Backend Wiring (8-10 hours)

**Deliverables**:
- [ ] Fetch save slots from backend
- [ ] Create manual save
- [ ] Load save + restore full state
- [ ] Delete save

**Files to Modify**:
```
lib/features/saves/saves_screen.dart     (update)
  ├── Load save list from repository
  ├── Wire create button to POST endpoint
  ├── Wire load button to state restoration
  └── Wire delete button to DELETE endpoint
```

**Implementation Pattern**:
```dart
class SavesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch saves
    final savesAsync = ref.watch(saveHistoryProvider);
    
    return savesAsync.when(
      loading: () => LoadingWidget(),
      error: (err, stack) => ErrorWidget(message: err.toString()),
      data: (saves) => ListView(
        children: [
          // Manual saves
          ...saves.manualSaves.map((save) => SaveSlotCard(
            save: save,
            onLoad: () => _loadSave(ref, save),
            onDelete: () => _deleteSave(ref, save),
          )),
          // Autosaves
          ...saves.autosaves.map((save) => SaveSlotCard(save: save, ...)),
          // Checkpoints
          ...saves.checkpoints.map((save) => SaveSlotCard(save: save, ...)),
        ],
      ),
    );
  }
  
  Future<void> _loadSave(WidgetRef ref, SaveSlot save) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Load save?'),
          content: Text('Progress since this save will be lost.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), 
              child: Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), 
              child: Text('Load')),
          ],
        ),
      );
      
      if (confirmed ?? false) {
        // Trigger load provider and wait
        await ref.read(loadSaveProvider(save).future);
        
        // Navigate back to play screen
        Navigator.of(context).pushReplacementNamed('/play');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load save: $e'))
      );
    }
  }
}
```

**Exit Criteria**:
- Save list displays all manual/auto/checkpoint saves
- Create manual save works and refreshes list
- Load save restores full character, quests, inventory, relationships
- Delete save works and updates list

---

### Phase 4.2: Rollback Implementation (7-10 hours)

**Deliverables**:
- [ ] Revision history modal
- [ ] Rollback confirmation dialog
- [ ] Rollback API call
- [ ] State restoration post-rollback

**Files to Create**:
```
lib/features/saves/rollback/
  ├── revision_history_modal.dart        (Show revisions)
  ├── rollback_confirmation_dialog.dart  (Confirmation + warnings)
  └── rollback_controller.dart           (Orchestrate rollback)
```

**Implementation Pattern**:
```dart
class RollbackModal extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch revision history from character state
    final revisions = ref.watch(revisionHistoryProvider);
    
    return Dialog(
      child: Column(
        children: [
          Text('Restore to a previous moment'),
          ListView.builder(
            itemCount: revisions.length,
            itemBuilder: (ctx, idx) {
              final rev = revisions[idx];
              return ListTile(
                title: Text('Turn ${rev.turnNumber}'),
                subtitle: Text(rev.location),
                trailing: Text(rev.timestamp),
                onTap: () => _showRollbackConfirmation(
                  context, ref, rev
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _showRollbackConfirmation(
    BuildContext context,
    WidgetRef ref,
    Revision revision,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rollback?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will restore your game to:'),
            SizedBox(height: 8),
            Text('Turn ${revision.turnNumber}', 
              style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Location: ${revision.location}'),
            SizedBox(height: 8),
            Text('All progress since then will be lost.',
              style: TextStyle(color: Colors.yellow)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Rollback'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirmed ?? false) {
      try {
        await ref.read(rollbackProvider(revision.revisionId).future);
        
        // Refresh authoritative state
        ref.invalidate(gameStateProvider);
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Game restored.'))
        );
        
        // Return to play
        Navigator.of(context).pushReplacementNamed('/play');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rollback failed: $e'))
        );
      }
    }
  }
}
```

**Exit Criteria**:
- Revision history displays all revisions for current run
- Rollback confirmation shows turn number, location, timestamp
- Rollback API call succeeds
- State is fully restored after rollback

---

## Milestone 5: Settings & Accessibility (8-12 hours)

### Phase 5.1: Dynamic Theme Application (3-4 hours)

**Deliverables**:
- [ ] Font size multiplier bound to all text widgets
- [ ] High contrast toggle switches color scheme
- [ ] Reduce motion toggle disables animations

**Files to Modify**:
```
lib/app/theme/app_theme.dart             (update)
  └── Add computed theme variants based on accessibility settings

lib/features/settings/settings_screen.dart (update)
  └── Wire toggles to Riverpod accessibility providers
```

**Implementation Pattern**:
```dart
// In app_theme.dart
ThemeData buildAppTheme(AccessibilitySettings settings) {
  final fontScale = settings.fontSizeMultiplier;
  
  return ThemeData(
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 32 * fontScale),
      displayMedium: TextStyle(fontSize: 28 * fontScale),
      bodyLarge: TextStyle(fontSize: 16 * fontScale),
      bodyMedium: TextStyle(fontSize: 14 * fontScale),
      // ...
    ),
    colorScheme: settings.highContrast
      ? _highContrastColorScheme()  // More vibrant colors
      : _normalColorScheme(),        // Muted dark fantasy
  );
}

// In settings_screen.dart
Slider(
  value: ref.watch(fontSizeMultiplierProvider),
  min: 0.8,
  max: 1.5,
  onChanged: (newValue) => 
    ref.read(fontSizeMultiplierProvider.notifier).state = newValue,
  label: 'Font size: ${(fontSizeMultiplierProvider * 100).toStringAsFixed(0)}%',
),
```

**Exit Criteria**:
- Font size multiplier scales all text proportionally
- High contrast switches color scheme globally
- Theme updates in real-time without app restart

---

### Phase 5.2: Accessibility Settings Enforcement (2-3 hours)

**Deliverables**:
- [ ] Pass content settings to narration request
- [ ] Filter sensitive content in codex/quests based on settings
- [ ] Apply constraints from Safety Gateway

**Implementation Notes**:
- Content filtering happens client-side (additional safety layer)
- Settings are included in turn request (backend knows player preferences)
- Fail-open: if filtering fails, show content anyway

**Exit Criteria**:
- Violence level setting filters narrative descriptions
- Romance toggle hides romance scenes
- Mature theme setting hides inappropriate content

---

### Phase 5.3: Reduce Motion Implementation (3-5 hours)

**Deliverables**:
- [ ] Bind all animations to reduce motion setting
- [ ] Skip animations immediately if enabled
- [ ] Test accessibility on screen readers

**Files to Create**:
```
lib/shared/animations/
  └── accessibility_animation_duration.dart
```

**Implementation Pattern**:
```dart
class AccessibleAnimation extends ConsumerWidget {
  final Widget child;
  final Duration normalDuration;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(reduceMotionProvider);
    final duration = reduceMotion 
      ? Duration.zero 
      : normalDuration;
    
    return AnimatedOpacity(
      duration: duration,
      opacity: 1.0,
      child: child,
    );
  }
}
```

**Exit Criteria**:
- All animations respond to reduce motion setting
- Animations are instant when enabled (no visual delay)
- Screen readers can navigate without animation blocking

---

## Milestone 6: Testing & Debugging (15-20 hours)

### Phase 6.1: Network Testing & Mocking (5-6 hours)

**Deliverables**:
- [ ] Mock HTTP responses for all API endpoints
- [ ] Test scenarios: success, clarification, conflict, rejection
- [ ] Retry logic under failure conditions
- [ ] Timeout handling

**Files to Create**:
```
lib/data/services/
  └── mock_http_client.dart              (for testing)

test/services/
  ├── http_client_service_test.dart
  ├── turn_repository_test.dart
  ├── save_repository_test.dart
  └── rollback_repository_test.dart
```

**Testing Scenarios**:
- ✅ Successful turn submission
- ✅ Clarification required (3 attempts)
- ✅ Idempotency conflict (same key, different payload)
- ✅ Safe reject (policy blocked)
- ✅ Network timeout (retry 3x)
- ✅ Malformed response (DTO parsing error)

**Exit Criteria**:
- All repository methods are testable
- Mock HTTP responses match backend schema
- Tests cover success + all major error paths

---

### Phase 6.2: State Synchronization Tests (4-5 hours)

**Deliverables**:
- [ ] Verify character updates post-turn
- [ ] Verify save/load restores full state
- [ ] Verify rollback works without corruption

**Files to Create**:
```
test/providers/
  ├── turn_submission_test.dart
  ├── save_load_test.dart
  ├── rollback_test.dart
  └── state_synchronization_test.dart
```

**Test Scenarios**:
- Turn submission updates HP correctly
- Save creation persists state
- Load restore brings back all providers
- Rollback doesn't lose other saves
- Multi-turn sequence maintains state integrity

**Exit Criteria**:
- All Riverpod providers sync correctly
- No state leakage between tests
- Save/load/rollback are reversible

---

### Phase 6.3: End-to-End Gameplay Tests (3-4 hours)

**Deliverables**:
- [ ] Full turn loop (input → API → render)
- [ ] Save/load/rollback workflows
- [ ] Clarification follow-ups
- [ ] Settings application

**Files to Create**:
```
test/features/play/
  ├── full_turn_loop_test.dart
  ├── clarification_flow_test.dart
  └── save_load_rollback_test.dart
```

**Exit Criteria**:
- Complete gameplay loops work end-to-end
- No null reference errors
- Settings changes apply immediately

---

### Phase 6.4: Debug Build Runner Issues (3-5 hours)

**Current Issues** (from your terminal output):
- `flutter run -d edge` → Exit code 1
- `dart run build_runner build --delete-conflicting-outputs` → Exit code 1

**Debugging Steps**:
1. Run `flutter clean` and `dart clean`
2. Run `flutter pub get` to refresh dependencies
3. Check for conflicting serialization annotations
4. Verify all `@JsonSerializable()` DTOs have factories
5. Check `pubspec.yaml` for circular dependencies
6. Run `dart run build_runner build -v` for verbose output
7. Review generated files in `.dart_tool/build/`

**Files to Create** (if needed):
```
lib/generated/
  └── (flutter_gen + source_gen outputs, auto-generated)
```

**Exit Criteria**:
- `flutter pub get` succeeds
- `dart run build_runner build` completes without errors
- `flutter run` launches the app

---

## Milestone 7: Polish & Readiness (10-15 hours)

### Phase 7.1: Error Messages & User Feedback (5-8 hours)

**Deliverables**:
- [ ] Friendly error messages for network failures
- [ ] Retry prompts for transient errors
- [ ] Loading skeletons for slow APIs
- [ ] Offline mode detection

**Implementation Notes**:
- Network error → "Connection lost. Retrying..."
- Timeout → "Action taking longer than expected. Still trying..."
- Conflict → "Your action conflicted with another change. Please try again."
- Policy reject → "This action cannot proceed. [reason]" (backend-provided)

**Exit Criteria**:
- No technical error messages shown to players
- All errors have a clear action (retry, cancel, try different action)

---

### Phase 7.2: Performance Profiling (3-5 hours)

**Deliverables**:
- [ ] Profile turn submission latency (target: p95 < 5s)
- [ ] Profile state sync latency (target: < 500ms)
- [ ] Identify slow providers
- [ ] Optimize hot paths

**Tools**:
- Flutter DevTools performance profiler
- Riverpod logger middleware
- Custom latency instrumentation

**Exit Criteria**:
- Turn submission p95 latency < 5s
- State sync completes < 500ms
- No jank during state updates

---

### Phase 7.3: Release Checklist (2-2 hours)

**Deliverables**:
- [ ] All endpoints tested against real backend
- [ ] Edge cases handled (offline, timeout, conflict, rejection)
- [ ] Accessibility pass (keyboard nav, screen reader, contrast)
- [ ] Documentation of API contract drift (if any)

**Verification Steps**:
- [ ] Local backend running, all endpoints respond
- [ ] Turn submission works end-to-end
- [ ] Save/load/rollback work end-to-end
- [ ] Clarification flow works
- [ ] Settings apply
- [ ] No console errors or warnings
- [ ] No memory leaks (profile with DevTools)

**Exit Criteria**:
- Phase 5 exit gate is satisfied: "A player can complete the full loop from input to authoritative result to save/load/rollback"
- Zero blocking bugs
- Ready for QA/playtesting

---

## Risk Mitigation & Fallback Plans

### Risk 1: Backend API Contract Changes
**Impact**: Cascading mapper/DTO rewrites (10-15 hours)
**Mitigation**:
- Lock API contract before starting Phase 1.2
- Run integration tests weekly against real backend
- Version API responses; support multiple versions if needed

### Risk 2: Riverpod State Inconsistency
**Impact**: Complex debugging, state corruption (5-10 hours)
**Mitigation**:
- Test each provider in isolation
- Use Riverpod logger to track state changes
- Create invariant assertions (character HP never negative, etc.)

### Risk 3: Idempotency Conflict Edge Cases
**Impact**: Subtle logic errors, hard to reproduce (5-10 hours)
**Mitigation**:
- Test conflict detection thoroughly
- Log conflict events for analysis
- Implement client-side hash verification

### Risk 4: Build Runner Codegen Failures
**Impact**: Blocker if unresolved (3-8 hours)
**Mitigation**:
- Keep Dart/Flutter up-to-date
- Use official serialization packages (json_annotation, freezed)
- Isolate problematic DTOs into separate file to pinpoint root cause

### Risk 5: Network Latency Exceeds Budget
**Impact**: Gameplay feels slow (5-10 hours for optimization)
**Mitigation**:
- Profile early (Phase 6.2)
- Use caching aggressively (save metadata in local storage)
- Consider request batching (fetch multiple resources in one call)

---

## Success Criteria: Phase 5 Exit Gate

Per PLAN.md: *"A player can complete the full loop from input to authoritative result to save/load/rollback without any client-side invention of canonical state."*

**Verification Checklist**:
- [ ] Player submits action via text input ✅ Input ready
- [ ] Action is sanitized and validated ✅ UI ready, backend gate not yet wired
- [ ] Action is routed deterministically ✅ Backend ready
- [ ] Simulation computes result ✅ Backend ready
- [ ] **One revision is committed atomically** ← **Wiring needed (Phase 3.1)**
- [ ] Canonical events are created ← **Wiring needed (Phase 3.1)**
- [ ] Character state delta is applied ← **Wiring needed (Phase 3.2)**
- [ ] Autosave eligibility is checked ← **Wiring needed (Phase 4.1)**
- [ ] Player sees turn result in narrative history ← **Wiring needed (Phase 3.1)**
- [ ] Player can save current state ← **Wiring needed (Phase 4.1)**
- [ ] Player can load any previous save ← **Wiring needed (Phase 4.1)**
- [ ] Player can rollback to any revision ← **Wiring needed (Phase 4.2)**
- [ ] Rolled-back state matches backend response ← **Wiring needed (Phase 4.2)**
- [ ] **No client-side invention of canonical outcomes** ← **Enforced by architecture**

---

## Timeline Summary

| Milestone | Hours | Duration (@ 25 hrs/week) | Weeks |
|-----------|-------|--------------------------|-------|
| 1. HTTP & Repos | 40-50 | 1.6-2.0 | 2 |
| 2. Riverpod Wiring | 15-20 | 0.6-0.8 | 1 |
| 3. Gameplay Loop | 20-30 | 0.8-1.2 | 1 |
| 4. Save/Load/Rollback | 15-20 | 0.6-0.8 | 1 |
| 5. Settings & A11y | 8-12 | 0.3-0.5 | 0.5 |
| 6. Testing & Debug | 15-20 | 0.6-0.8 | 1 |
| 7. Polish & Release | 10-15 | 0.4-0.6 | 0.5 |
| **TOTAL** | **123-167** | **5-7** | **6-7** |

**Realistic estimate with buffer: 135 hours over 6 weeks**

---

## Next Steps

1. **Immediate (Today)**:
   - Confirm API contract (endpoints, request/response shapes)
   - Resolve build_runner errors
   - Set up HTTP client service skeleton

2. **Week 1**:
   - Complete all DTOs and mappers
   - Build repository layer
   - Verify against backend API

3. **Week 2**:
   - Wire Riverpod providers
   - Test state hydration on app startup

4. **Week 3**:
   - Implement turn submission
   - Wire canonical event rendering

5. **Week 4**:
   - Implement save/load/rollback
   - Test full workflows

6. **Week 5**:
   - Settings & accessibility
   - Comprehensive testing

7. **Week 6**:
   - Performance profiling
   - Release readiness verification
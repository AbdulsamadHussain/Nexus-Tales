import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/turn_repository.dart';
import '../../data/repositories/turn_repository_impl.dart';
import '../../data/repositories/save_repository.dart';
import '../../data/repositories/save_repository_impl.dart';
import '../../data/repositories/rollback_repository.dart';
import '../../data/repositories/rollback_repository_impl.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/repositories/character_repository_impl.dart';
import '../../data/dto/turn_dto.dart';
import '../../domain/models/game_models.dart';
import 'http_client_provider.dart';

part 'repository_providers.g.dart';

/// Provides TurnRepository for submitting turn actions
@riverpod
TurnRepository turnRepository(TurnRepositoryRef ref) {
  return TurnRepositoryImpl(
    httpClient: ref.watch(httpClientProvider),
  );
}

/// Provides SaveRepository for creating, loading, and deleting saves
@riverpod
SaveRepository saveRepository(SaveRepositoryRef ref) {
  return SaveRepositoryImpl(
    httpClient: ref.watch(httpClientProvider),
  );
}

/// Provides RollbackRepository for rolling back to previous revisions
@riverpod
RollbackRepository rollbackRepository(RollbackRepositoryRef ref) {
  return RollbackRepositoryImpl(
    httpClient: ref.watch(httpClientProvider),
  );
}

/// Provides CharacterRepository for loading character and related data
@riverpod
CharacterRepository characterRepository(CharacterRepositoryRef ref) {
  return CharacterRepositoryImpl(
    httpClient: ref.watch(httpClientProvider),
  );
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
@riverpod
Future<TurnResult> submitTurn(
  SubmitTurnRef ref, {
  required String action,
  required String runId,
  required String saveSlotId,
}) async {
  final repo = ref.read(turnRepositoryProvider);
  
  // Create turn request
  final request = TurnRequestDto(
    clientTurnId: 'client-${DateTime.now().millisecondsSinceEpoch}',
    runId: runId,
    saveSlotId: saveSlotId,
    action: action,
    sceneFingerprint: 'scene-fingerprint',
    schemaVersion: 1,
  );
  
  // Submit to backend
  return repo.submitTurn(request);
}

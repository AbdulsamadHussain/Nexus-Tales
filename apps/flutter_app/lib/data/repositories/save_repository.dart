import '../dto/save_dto.dart';
import '../../domain/models/game_models.dart';

/// Repository interface for save/load operations
abstract class SaveRepository {
  /// Create a manual save at current game state
  /// 
  /// Throws [SaveSlotExhaustedException] if no slots available
  /// Throws [NetworkException] on network failures
  Future<SaveSlot> createManualSave(SaveRequestDto request);

  /// Fetch all saves (manual, autosaves, checkpoints) for a game run
  Future<List<SaveSlot>> fetchSaves(String runId, String saveSlotId);

  /// Load a specific save and return full game state snapshot
  /// 
  /// Returns the game state as restored from the server
  /// Throws [NetworkException] on network failures
  Future<Map<String, dynamic>> loadSave(String saveSlotId);

  /// Delete a manual save
  Future<void> deleteManualSave(String saveId);

  /// Get all save metadata without loading full snapshots
  Future<SaveSlotsDto> fetchSaveMetadata(String runId);
}

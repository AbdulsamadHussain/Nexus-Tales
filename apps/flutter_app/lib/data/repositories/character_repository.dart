import '../../domain/models/game_models.dart';

/// Repository interface for character and state hydration
abstract class CharacterRepository {
  /// Fetch character state from backend
  Future<PlayerCharacter> fetchCharacter(String runId, String saveSlotId);

  /// Fetch player quests with current progress
  Future<List<Quest>> fetchQuests(String runId);

  /// Fetch player inventory
  Future<List<InventoryItem>> fetchInventory(String runId);

  /// Fetch discovered codex entries
  Future<List<CodexEntry>> fetchCodexEntries(String runId);

  /// Fetch faction standings
  Future<List<Faction>> fetchFactions(String runId);

  /// Fetch NPC relationships
  Future<List<Relationship>> fetchRelationships(String runId);

  /// Parallel fetch of all authoritative remote state
  /// Returns complete game state or null if session invalid
  Future<Map<String, dynamic>?> hydrateCompleteState(
    String runId,
    String saveSlotId,
  );
}

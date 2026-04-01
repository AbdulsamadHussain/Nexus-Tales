import '../../domain/models/game_models.dart';
import '../dto/save_dto.dart';
import 'character_mapper.dart';
import 'mapper_utils.dart';

/// Mapper for save-related DTOs to domain models

class SaveMapper {
  /// Convert SaveSlotDto to SaveSlot domain model
  static SaveSlot toSaveSlot(SaveSlotDto dto) {
    return SaveSlot(
      id: dto.manualSaveId ?? dto.saveSlotId,
      campaignTitle: 'Current Campaign', // Not provided by API
      characterName: 'Unknown', // Not provided by API
      location: dto.location,
      currentChapter: _formatChapter(dto.chapterNumber),
      lastSavedAt: dto.timestamp,
      isAutosave: dto.saveType == 'AUTOSAVE',
      isCheckpoint: dto.saveType == 'CHECKPOINT',
      revisionNumber: dto.turnNumber,
      playtimeMinutes: 0, // Not provided by API
      thumbnailUrl: '',
    );
  }

  /// Convert SaveSnapshotDto to a map for game state restoration
  static Map<String, dynamic> toGameStateMap(SaveSnapshotDto dto) {
    return {
      'save_slot_id': dto.saveSlotId,
      'revision_id': dto.revisionId,
      'timestamp': dto.timestamp.toIso8601String(),
      'location': dto.location,
      'chapter_number': dto.chapterNumber,
      'quest_milestone': dto.questMilestone,
      'turn_number': dto.turnNumber,
      'character_snapshot': dto.characterSnapshot,
      'game_state_snapshot': dto.gameStateSnapshot,
      'schema_version': dto.schemaVersion,
    };
  }

  // Private helpers

  static String _formatChapter(int chapterNumber) {
    return 'Chapter $chapterNumber';
  }
}

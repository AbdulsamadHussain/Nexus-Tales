import 'package:json_annotation/json_annotation.dart';

part 'save_dto.g.dart';

/// Request to create a manual save
@JsonSerializable()
class SaveRequestDto {
  @JsonKey(name: 'run_id')
  final String runId;

  @JsonKey(name: 'save_slot_id')
  final String saveSlotId;

  final String location;

  @JsonKey(name: 'chapter_number')
  final int chapterNumber;

  @JsonKey(name: 'quest_milestone')
  final String? questMilestone;

  final String notes;

  SaveRequestDto({
    required this.runId,
    required this.saveSlotId,
    required this.location,
    required this.chapterNumber,
    this.questMilestone,
    this.notes = '',
  });

  factory SaveRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SaveRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SaveRequestDtoToJson(this);
}

/// Save slot metadata
@JsonSerializable()
class SaveSlotDto {
  @JsonKey(name: 'save_slot_id')
  final String saveSlotId;

  @JsonKey(name: 'save_type')
  final String saveType; // 'MANUAL', 'AUTOSAVE', 'CHECKPOINT'

  @JsonKey(name: 'manual_save_id')
  final String? manualSaveId;

  @JsonKey(name: 'revision_id')
  final String revisionId;

  final DateTime timestamp;

  final String location;

  @JsonKey(name: 'chapter_number')
  final int chapterNumber;

  @JsonKey(name: 'quest_milestone')
  final String? questMilestone;

  @JsonKey(name: 'turn_number')
  final int turnNumber;

  final String? notes;

  SaveSlotDto({
    required this.saveSlotId,
    required this.saveType,
    this.manualSaveId,
    required this.revisionId,
    required this.timestamp,
    required this.location,
    required this.chapterNumber,
    this.questMilestone,
    required this.turnNumber,
    this.notes,
  });

  factory SaveSlotDto.fromJson(Map<String, dynamic> json) =>
      _$SaveSlotDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SaveSlotDtoToJson(this);
}

/// Complete save snapshot (used when loading a save)
@JsonSerializable()
class SaveSnapshotDto {
  @JsonKey(name: 'save_slot_id')
  final String saveSlotId;

  @JsonKey(name: 'revision_id')
  final String revisionId;

  final DateTime timestamp;

  final String location;

  @JsonKey(name: 'chapter_number')
  final int chapterNumber;

  @JsonKey(name: 'quest_milestone')
  final String? questMilestone;

  @JsonKey(name: 'turn_number')
  final int turnNumber;

  @JsonKey(name: 'character_snapshot')
  final Map<String, dynamic> characterSnapshot;

  @JsonKey(name: 'game_state_snapshot')
  final Map<String, dynamic> gameStateSnapshot;

  @JsonKey(name: 'schema_version')
  final int schemaVersion;

  SaveSnapshotDto({
    required this.saveSlotId,
    required this.revisionId,
    required this.timestamp,
    required this.location,
    required this.chapterNumber,
    this.questMilestone,
    required this.turnNumber,
    required this.characterSnapshot,
    required this.gameStateSnapshot,
    this.schemaVersion = 1,
  });

  factory SaveSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$SaveSnapshotDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SaveSnapshotDtoToJson(this);
}

/// List of all save slots for a game
@JsonSerializable()
class SaveSlotsDto {
  @JsonKey(name: 'run_id')
  final String runId;

  @JsonKey(name: 'manual_saves')
  final List<SaveSlotDto> manualSaves;

  final List<SaveSlotDto> autosaves;

  final List<SaveSlotDto> checkpoints;

  SaveSlotsDto({
    required this.runId,
    required this.manualSaves,
    required this.autosaves,
    required this.checkpoints,
  });

  factory SaveSlotsDto.fromJson(Map<String, dynamic> json) =>
      _$SaveSlotsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SaveSlotsDtoToJson(this);
}

/// Response when creating a manual save
@JsonSerializable()
class CreateSaveResponseDto {
  @JsonKey(name: 'save_slot_id')
  final String saveSlotId;

  @JsonKey(name: 'manual_save_id')
  final String manualSaveId;

  @JsonKey(name: 'revision_id')
  final String revisionId;

  final DateTime timestamp;

  CreateSaveResponseDto({
    required this.saveSlotId,
    required this.manualSaveId,
    required this.revisionId,
    required this.timestamp,
  });

  factory CreateSaveResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CreateSaveResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSaveResponseDtoToJson(this);
}

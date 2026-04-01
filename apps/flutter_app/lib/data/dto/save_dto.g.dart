// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveRequestDto _$SaveRequestDtoFromJson(Map<String, dynamic> json) =>
    SaveRequestDto(
      runId: json['run_id'] as String,
      saveSlotId: json['save_slot_id'] as String,
      location: json['location'] as String,
      chapterNumber: (json['chapter_number'] as num).toInt(),
      questMilestone: json['quest_milestone'] as String?,
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$SaveRequestDtoToJson(SaveRequestDto instance) =>
    <String, dynamic>{
      'run_id': instance.runId,
      'save_slot_id': instance.saveSlotId,
      'location': instance.location,
      'chapter_number': instance.chapterNumber,
      'quest_milestone': instance.questMilestone,
      'notes': instance.notes,
    };

SaveSlotDto _$SaveSlotDtoFromJson(Map<String, dynamic> json) => SaveSlotDto(
      saveSlotId: json['save_slot_id'] as String,
      saveType: json['save_type'] as String,
      manualSaveId: json['manual_save_id'] as String?,
      revisionId: json['revision_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: json['location'] as String,
      chapterNumber: (json['chapter_number'] as num).toInt(),
      questMilestone: json['quest_milestone'] as String?,
      turnNumber: (json['turn_number'] as num).toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SaveSlotDtoToJson(SaveSlotDto instance) =>
    <String, dynamic>{
      'save_slot_id': instance.saveSlotId,
      'save_type': instance.saveType,
      'manual_save_id': instance.manualSaveId,
      'revision_id': instance.revisionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'location': instance.location,
      'chapter_number': instance.chapterNumber,
      'quest_milestone': instance.questMilestone,
      'turn_number': instance.turnNumber,
      'notes': instance.notes,
    };

SaveSnapshotDto _$SaveSnapshotDtoFromJson(Map<String, dynamic> json) =>
    SaveSnapshotDto(
      saveSlotId: json['save_slot_id'] as String,
      revisionId: json['revision_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: json['location'] as String,
      chapterNumber: (json['chapter_number'] as num).toInt(),
      questMilestone: json['quest_milestone'] as String?,
      turnNumber: (json['turn_number'] as num).toInt(),
      characterSnapshot: json['character_snapshot'] as Map<String, dynamic>,
      gameStateSnapshot: json['game_state_snapshot'] as Map<String, dynamic>,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$SaveSnapshotDtoToJson(SaveSnapshotDto instance) =>
    <String, dynamic>{
      'save_slot_id': instance.saveSlotId,
      'revision_id': instance.revisionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'location': instance.location,
      'chapter_number': instance.chapterNumber,
      'quest_milestone': instance.questMilestone,
      'turn_number': instance.turnNumber,
      'character_snapshot': instance.characterSnapshot,
      'game_state_snapshot': instance.gameStateSnapshot,
      'schema_version': instance.schemaVersion,
    };

SaveSlotsDto _$SaveSlotsDtoFromJson(Map<String, dynamic> json) => SaveSlotsDto(
      runId: json['run_id'] as String,
      manualSaves: (json['manual_saves'] as List<dynamic>)
          .map((e) => SaveSlotDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      autosaves: (json['autosaves'] as List<dynamic>)
          .map((e) => SaveSlotDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) => SaveSlotDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SaveSlotsDtoToJson(SaveSlotsDto instance) =>
    <String, dynamic>{
      'run_id': instance.runId,
      'manual_saves': instance.manualSaves,
      'autosaves': instance.autosaves,
      'checkpoints': instance.checkpoints,
    };

CreateSaveResponseDto _$CreateSaveResponseDtoFromJson(
        Map<String, dynamic> json) =>
    CreateSaveResponseDto(
      saveSlotId: json['save_slot_id'] as String,
      manualSaveId: json['manual_save_id'] as String,
      revisionId: json['revision_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$CreateSaveResponseDtoToJson(
        CreateSaveResponseDto instance) =>
    <String, dynamic>{
      'save_slot_id': instance.saveSlotId,
      'manual_save_id': instance.manualSaveId,
      'revision_id': instance.revisionId,
      'timestamp': instance.timestamp.toIso8601String(),
    };

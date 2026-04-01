// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rollback_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RollbackRequestDto _$RollbackRequestDtoFromJson(Map<String, dynamic> json) =>
    RollbackRequestDto(
      runId: json['run_id'] as String,
      saveSlotId: json['save_slot_id'] as String,
      revisionId: json['revision_id'] as String,
    );

Map<String, dynamic> _$RollbackRequestDtoToJson(RollbackRequestDto instance) =>
    <String, dynamic>{
      'run_id': instance.runId,
      'save_slot_id': instance.saveSlotId,
      'revision_id': instance.revisionId,
    };

RevisionHistoryDto _$RevisionHistoryDtoFromJson(Map<String, dynamic> json) =>
    RevisionHistoryDto(
      revisionId: json['revision_id'] as String,
      revisionNumber: (json['revision_number'] as num).toInt(),
      turnNumber: (json['turn_number'] as num).toInt(),
      location: json['location'] as String,
      chapterNumber: (json['chapter_number'] as num).toInt(),
      questMilestone: json['quest_milestone'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      actionSummary: json['action_summary'] as String?,
      htmlSummary: json['html_summary'] as String?,
      rollbackable: json['rollbackable'] as bool?,
    );

Map<String, dynamic> _$RevisionHistoryDtoToJson(RevisionHistoryDto instance) =>
    <String, dynamic>{
      'revision_id': instance.revisionId,
      'revision_number': instance.revisionNumber,
      'turn_number': instance.turnNumber,
      'location': instance.location,
      'chapter_number': instance.chapterNumber,
      'quest_milestone': instance.questMilestone,
      'timestamp': instance.timestamp.toIso8601String(),
      'action_summary': instance.actionSummary,
      'html_summary': instance.htmlSummary,
      'rollbackable': instance.rollbackable,
    };

RollbackResponseDto _$RollbackResponseDtoFromJson(Map<String, dynamic> json) =>
    RollbackResponseDto(
      revisionId: json['revision_id'] as String,
      success: json['success'] as bool,
      characterState: json['character_state'] == null
          ? null
          : CharacterStateDto.fromJson(
              json['character_state'] as Map<String, dynamic>),
      gameState: json['game_state'] as Map<String, dynamic>?,
      revisionsRemoved: (json['revisions_removed'] as num).toInt(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$RollbackResponseDtoToJson(
        RollbackResponseDto instance) =>
    <String, dynamic>{
      'revision_id': instance.revisionId,
      'success': instance.success,
      'character_state': instance.characterState,
      'game_state': instance.gameState,
      'revisions_removed': instance.revisionsRemoved,
      'message': instance.message,
    };

RevisionListDto _$RevisionListDtoFromJson(Map<String, dynamic> json) =>
    RevisionListDto(
      runId: json['run_id'] as String,
      revisions: (json['revisions'] as List<dynamic>)
          .map((e) => RevisionHistoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentRevisionId: json['current_revision_id'] as String,
    );

Map<String, dynamic> _$RevisionListDtoToJson(RevisionListDto instance) =>
    <String, dynamic>{
      'run_id': instance.runId,
      'revisions': instance.revisions,
      'current_revision_id': instance.currentRevisionId,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turn_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TurnRequestDto _$TurnRequestDtoFromJson(Map<String, dynamic> json) =>
    TurnRequestDto(
      clientTurnId: json['client_turn_id'] as String,
      runId: json['run_id'] as String,
      saveSlotId: json['save_slot_id'] as String,
      action: json['action'] as String,
      sceneFingerprint: json['scene_fingerprint'] as String,
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      clarificationAnswer: json['clarification_answer'] as String?,
    );

Map<String, dynamic> _$TurnRequestDtoToJson(TurnRequestDto instance) =>
    <String, dynamic>{
      'client_turn_id': instance.clientTurnId,
      'run_id': instance.runId,
      'save_slot_id': instance.saveSlotId,
      'action': instance.action,
      'scene_fingerprint': instance.sceneFingerprint,
      'schema_version': instance.schemaVersion,
      'clarification_answer': instance.clarificationAnswer,
    };

SimulationResultDto _$SimulationResultDtoFromJson(Map<String, dynamic> json) =>
    SimulationResultDto(
      actionOutcome: json['action_outcome'] as String,
      rollResult: json['roll_result'] as Map<String, dynamic>?,
      consequences: (json['consequences'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      canonicalEvents: (json['canonical_events'] as List<dynamic>?)
          ?.map((e) => CanonicalEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SimulationResultDtoToJson(
        SimulationResultDto instance) =>
    <String, dynamic>{
      'action_outcome': instance.actionOutcome,
      'roll_result': instance.rollResult,
      'consequences': instance.consequences,
      'canonical_events': instance.canonicalEvents,
    };

CharacterStateDeltaDto _$CharacterStateDeltaDtoFromJson(
        Map<String, dynamic> json) =>
    CharacterStateDeltaDto(
      hpDelta: (json['hpDelta'] as num?)?.toInt(),
      staminaDelta: (json['staminaDelta'] as num?)?.toInt(),
      manaDelta: (json['manaDelta'] as num?)?.toInt(),
      inventoryAdded: (json['inventory_added'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      inventoryRemoved: (json['inventory_removed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      questUpdates: (json['quest_updates'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      relationshipChanges: (json['relationship_changes'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      factionChanges: (json['faction_changes'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$CharacterStateDeltaDtoToJson(
        CharacterStateDeltaDto instance) =>
    <String, dynamic>{
      'hpDelta': instance.hpDelta,
      'staminaDelta': instance.staminaDelta,
      'manaDelta': instance.manaDelta,
      'inventory_added': instance.inventoryAdded,
      'inventory_removed': instance.inventoryRemoved,
      'quest_updates': instance.questUpdates,
      'relationship_changes': instance.relationshipChanges,
      'faction_changes': instance.factionChanges,
    };

TurnAuthoritativeResponseDto _$TurnAuthoritativeResponseDtoFromJson(
        Map<String, dynamic> json) =>
    TurnAuthoritativeResponseDto(
      status: json['status'] as String,
      revisionId: json['revision_id'] as String?,
      requestHash: json['request_hash'] as String?,
      simulationResult: json['simulation_result'] == null
          ? null
          : SimulationResultDto.fromJson(
              json['simulation_result'] as Map<String, dynamic>),
      characterStateDelta: json['character_state_delta'] == null
          ? null
          : CharacterStateDeltaDto.fromJson(
              json['character_state_delta'] as Map<String, dynamic>),
      autosaveEligible: json['autosave_eligible'] as bool?,
      clarificationPrompt: json['clarification_prompt'] as String?,
      clarificationContext:
          json['clarification_context'] as Map<String, dynamic>?,
      conflictOriginalHash: json['conflict_original_hash'] as String?,
      errorMessage: json['error_message'] as String?,
      errorCode: json['error_code'] as String?,
    );

Map<String, dynamic> _$TurnAuthoritativeResponseDtoToJson(
        TurnAuthoritativeResponseDto instance) =>
    <String, dynamic>{
      'status': instance.status,
      'revision_id': instance.revisionId,
      'request_hash': instance.requestHash,
      'simulation_result': instance.simulationResult,
      'character_state_delta': instance.characterStateDelta,
      'autosave_eligible': instance.autosaveEligible,
      'clarification_prompt': instance.clarificationPrompt,
      'clarification_context': instance.clarificationContext,
      'conflict_original_hash': instance.conflictOriginalHash,
      'error_message': instance.errorMessage,
      'error_code': instance.errorCode,
    };

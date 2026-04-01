import 'package:json_annotation/json_annotation.dart';
import 'common_dto.dart';

part 'turn_dto.g.dart';

/// Turn submission request
@JsonSerializable()
class TurnRequestDto {
  /// UUID from client - ensures idempotency
  @JsonKey(name: 'client_turn_id')
  final String clientTurnId;

  /// Current run/game session ID
  @JsonKey(name: 'run_id')
  final String runId;

  /// Current save slot ID (for autosave eligibility)
  @JsonKey(name: 'save_slot_id')
  final String saveSlotId;

  /// Player's action input (after validation)
  final String action;

  /// Scene fingerprint for ambiguity/clarification tracking
  @JsonKey(name: 'scene_fingerprint')
  final String sceneFingerprint;

  /// Schema version for safety
  @JsonKey(name: 'schema_version')
  final int schemaVersion;

  /// Clarification answer (if this is a retry with clarification)
  @JsonKey(name: 'clarification_answer')
  final String? clarificationAnswer;

  TurnRequestDto({
    required this.clientTurnId,
    required this.runId,
    required this.saveSlotId,
    required this.action,
    required this.sceneFingerprint,
    this.schemaVersion = 1,
    this.clarificationAnswer,
  });

  factory TurnRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TurnRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TurnRequestDtoToJson(this);
}

/// Simulation result from turn execution
@JsonSerializable()
class SimulationResultDto {
  /// Outcome of the action (SUCCESS, PARTIAL, FAILURE)
  @JsonKey(name: 'action_outcome')
  final String actionOutcome;

  /// Roll result details
  @JsonKey(name: 'roll_result')
  final Map<String, dynamic>? rollResult;

  /// List of consequences from the action
  final List<String>? consequences;

  /// Canonical events created by the simulation
  @JsonKey(name: 'canonical_events')
  final List<CanonicalEventDto>? canonicalEvents;

  SimulationResultDto({
    required this.actionOutcome,
    this.rollResult,
    this.consequences,
    this.canonicalEvents,
  });

  factory SimulationResultDto.fromJson(Map<String, dynamic> json) =>
      _$SimulationResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SimulationResultDtoToJson(this);
}

/// Character state delta (changes from turn)
@JsonSerializable()
class CharacterStateDeltaDto {
  /// HP change
  final int? hpDelta;

  /// Stamina change
  final int? staminaDelta;

  /// Mana change
  final int? manaDelta;

  /// Inventory items added
  @JsonKey(name: 'inventory_added')
  final List<Map<String, dynamic>>? inventoryAdded;

  /// Inventory items removed
  @JsonKey(name: 'inventory_removed')
  final List<String>? inventoryRemoved;

  /// Quest updates
  @JsonKey(name: 'quest_updates')
  final List<Map<String, dynamic>>? questUpdates;

  /// Relationship changes
  @JsonKey(name: 'relationship_changes')
  final List<Map<String, dynamic>>? relationshipChanges;

  /// Faction standing changes
  @JsonKey(name: 'faction_changes')
  final List<Map<String, dynamic>>? factionChanges;

  CharacterStateDeltaDto({
    this.hpDelta,
    this.staminaDelta,
    this.manaDelta,
    this.inventoryAdded,
    this.inventoryRemoved,
    this.questUpdates,
    this.relationshipChanges,
    this.factionChanges,
  });

  factory CharacterStateDeltaDto.fromJson(Map<String, dynamic> json) =>
      _$CharacterStateDeltaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CharacterStateDeltaDtoToJson(this);
}

/// Authoritative turn response from the backend
@JsonSerializable()
class TurnAuthoritativeResponseDto {
  /// Status of the turn submission
  final String status;

  /// Unique revision ID (only if ACCEPTED)
  @JsonKey(name: 'revision_id')
  final String? revisionId;

  /// Hash of the accepted request (for idempotency verification)
  @JsonKey(name: 'request_hash')
  final String? requestHash;

  /// Simulation result (if status is ACCEPTED)
  @JsonKey(name: 'simulation_result')
  final SimulationResultDto? simulationResult;

  /// Character state changes from the turn
  @JsonKey(name: 'character_state_delta')
  final CharacterStateDeltaDto? characterStateDelta;

  /// Whether an autosave should be triggered
  @JsonKey(name: 'autosave_eligible')
  final bool? autosaveEligible;

  /// Clarification prompt (if status is CLARIFICATION_REQUIRED)
  @JsonKey(name: 'clarification_prompt')
  final String? clarificationPrompt;

  /// Clarification context (if status is CLARIFICATION_REQUIRED)
  @JsonKey(name: 'clarification_context')
  final Map<String, dynamic>? clarificationContext;

  /// Original request hash (if status is CONFLICT)
  @JsonKey(name: 'conflict_original_hash')
  final String? conflictOriginalHash;

  /// Error message (if status is SAFE_REJECT)
  @JsonKey(name: 'error_message')
  final String? errorMessage;

  /// Error code for policy rejections
  @JsonKey(name: 'error_code')
  final String? errorCode;

  TurnAuthoritativeResponseDto({
    required this.status,
    this.revisionId,
    this.requestHash,
    this.simulationResult,
    this.characterStateDelta,
    this.autosaveEligible,
    this.clarificationPrompt,
    this.clarificationContext,
    this.conflictOriginalHash,
    this.errorMessage,
    this.errorCode,
  });

  factory TurnAuthoritativeResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TurnAuthoritativeResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TurnAuthoritativeResponseDtoToJson(this);
}

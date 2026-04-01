import 'package:json_annotation/json_annotation.dart';
import 'character_state_dto.dart';

part 'rollback_dto.g.dart';

/// Request to rollback to a specific revision
@JsonSerializable()
class RollbackRequestDto {
  @JsonKey(name: 'run_id')
  final String runId;

  @JsonKey(name: 'save_slot_id')
  final String saveSlotId;

  @JsonKey(name: 'revision_id')
  final String revisionId;

  RollbackRequestDto({
    required this.runId,
    required this.saveSlotId,
    required this.revisionId,
  });

  factory RollbackRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RollbackRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RollbackRequestDtoToJson(this);
}

/// Revision history entry for display
@JsonSerializable()
class RevisionHistoryDto {
  @JsonKey(name: 'revision_id')
  final String revisionId;

  @JsonKey(name: 'revision_number')
  final int revisionNumber;

  @JsonKey(name: 'turn_number')
  final int turnNumber;

  final String location;

  @JsonKey(name: 'chapter_number')
  final int chapterNumber;

  @JsonKey(name: 'quest_milestone')
  final String? questMilestone;

  final DateTime timestamp;

  @JsonKey(name: 'action_summary')
  final String? actionSummary;

  @JsonKey(name: 'html_summary')
  final String? htmlSummary;

  final bool? rollbackable;

  RevisionHistoryDto({
    required this.revisionId,
    required this.revisionNumber,
    required this.turnNumber,
    required this.location,
    required this.chapterNumber,
    this.questMilestone,
    required this.timestamp,
    this.actionSummary,
    this.htmlSummary,
    this.rollbackable,
  });

  factory RevisionHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$RevisionHistoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RevisionHistoryDtoToJson(this);
}

/// Response from rollback operation
@JsonSerializable()
class RollbackResponseDto {
  @JsonKey(name: 'revision_id')
  final String revisionId;

  final bool success;

  @JsonKey(name: 'character_state')
  final CharacterStateDto? characterState;

  @JsonKey(name: 'game_state')
  final Map<String, dynamic>? gameState;

  @JsonKey(name: 'revisions_removed')
  final int revisionsRemoved;

  final String? message;

  RollbackResponseDto({
    required this.revisionId,
    required this.success,
    this.characterState,
    this.gameState,
    required this.revisionsRemoved,
    this.message,
  });

  factory RollbackResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RollbackResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RollbackResponseDtoToJson(this);
}

/// List of available revisions for rollback
@JsonSerializable()
class RevisionListDto {
  @JsonKey(name: 'run_id')
  final String runId;

  final List<RevisionHistoryDto> revisions;

  @JsonKey(name: 'current_revision_id')
  final String currentRevisionId;

  RevisionListDto({
    required this.runId,
    required this.revisions,
    required this.currentRevisionId,
  });

  factory RevisionListDto.fromJson(Map<String, dynamic> json) =>
      _$RevisionListDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RevisionListDtoToJson(this);
}

import 'package:json_annotation/json_annotation.dart';

part 'common_dto.g.dart';

/// Common DTOs shared across all API responses

/// Turn status values
enum TurnStatus {
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('CLARIFICATION_REQUIRED')
  clarificationRequired,
  @JsonValue('SAFE_REJECT')
  safeReject,
  @JsonValue('CONFLICT')
  conflict,
}

/// Action outcome values
enum ActionOutcome {
  @JsonValue('SUCCESS')
  success,
  @JsonValue('PARTIAL')
  partial,
  @JsonValue('FAILURE')
  failure,
}

/// Generic API response wrapper
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final String status;
  final T? data;
  final String? message;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.status,
    this.data,
    this.message,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}

/// Error details from API
@JsonSerializable()
class ErrorDetail {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  ErrorDetail({
    required this.code,
    required this.message,
    this.details,
  });

  factory ErrorDetail.fromJson(Map<String, dynamic> json) =>
      _$ErrorDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorDetailToJson(this);
}

/// Pagination metadata
@JsonSerializable()
class PaginationMeta {
  final int total;
  final int count;
  final int page;
  final int pageSize;

  PaginationMeta({
    required this.total,
    required this.count,
    required this.page,
    required this.pageSize,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetaToJson(this);
}

/// State delta (for partial updates)
@JsonSerializable()
class StateDelta {
  final Map<String, dynamic>? properties;
  final List<String>? removedKeys;

  StateDelta({
    this.properties,
    this.removedKeys,
  });

  factory StateDelta.fromJson(Map<String, dynamic> json) =>
      _$StateDeltaFromJson(json);

  Map<String, dynamic> toJson() => _$StateDeltaToJson(this);
}

/// Canonical event from simulation
@JsonSerializable()
class CanonicalEventDto {
  final String eventId;
  final String eventType;
  final String description;
  final Map<String, dynamic>? consequences;
  final int? rollSum;
  final int? targetDC;

  CanonicalEventDto({
    required this.eventId,
    required this.eventType,
    required this.description,
    this.consequences,
    this.rollSum,
    this.targetDC,
  });

  factory CanonicalEventDto.fromJson(Map<String, dynamic> json) =>
      _$CanonicalEventDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CanonicalEventDtoToJson(this);
}

/// Base revision metadata
@JsonSerializable()
class RevisionMetadata {
  final String revisionId;
  final int revisionNumber;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  RevisionMetadata({
    required this.revisionId,
    required this.revisionNumber,
    required this.createdAt,
    this.metadata,
  });

  factory RevisionMetadata.fromJson(Map<String, dynamic> json) =>
      _$RevisionMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$RevisionMetadataToJson(this);
}

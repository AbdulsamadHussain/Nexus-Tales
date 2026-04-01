// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'common_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResponse<T> _$ApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    ApiResponse<T>(
      status: json['status'] as String,
      data: _$nullableGenericFromJson(json['data'], fromJsonT),
      message: json['message'] as String?,
      errors: json['errors'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ApiResponseToJson<T>(
  ApiResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'status': instance.status,
      'data': _$nullableGenericToJson(instance.data, toJsonT),
      'message': instance.message,
      'errors': instance.errors,
    };

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);

ErrorDetail _$ErrorDetailFromJson(Map<String, dynamic> json) => ErrorDetail(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ErrorDetailToJson(ErrorDetail instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'details': instance.details,
    };

PaginationMeta _$PaginationMetaFromJson(Map<String, dynamic> json) =>
    PaginationMeta(
      total: (json['total'] as num).toInt(),
      count: (json['count'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationMetaToJson(PaginationMeta instance) =>
    <String, dynamic>{
      'total': instance.total,
      'count': instance.count,
      'page': instance.page,
      'pageSize': instance.pageSize,
    };

StateDelta _$StateDeltaFromJson(Map<String, dynamic> json) => StateDelta(
      properties: json['properties'] as Map<String, dynamic>?,
      removedKeys: (json['removedKeys'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$StateDeltaToJson(StateDelta instance) =>
    <String, dynamic>{
      'properties': instance.properties,
      'removedKeys': instance.removedKeys,
    };

CanonicalEventDto _$CanonicalEventDtoFromJson(Map<String, dynamic> json) =>
    CanonicalEventDto(
      eventId: json['eventId'] as String,
      eventType: json['eventType'] as String,
      description: json['description'] as String,
      consequences: json['consequences'] as Map<String, dynamic>?,
      rollSum: (json['rollSum'] as num?)?.toInt(),
      targetDC: (json['targetDC'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CanonicalEventDtoToJson(CanonicalEventDto instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'eventType': instance.eventType,
      'description': instance.description,
      'consequences': instance.consequences,
      'rollSum': instance.rollSum,
      'targetDC': instance.targetDC,
    };

RevisionMetadata _$RevisionMetadataFromJson(Map<String, dynamic> json) =>
    RevisionMetadata(
      revisionId: json['revisionId'] as String,
      revisionNumber: (json['revisionNumber'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RevisionMetadataToJson(RevisionMetadata instance) =>
    <String, dynamic>{
      'revisionId': instance.revisionId,
      'revisionNumber': instance.revisionNumber,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
    };

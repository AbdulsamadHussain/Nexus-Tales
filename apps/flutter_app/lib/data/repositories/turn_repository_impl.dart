import 'package:uuid/uuid.dart';

import '../dto/turn_dto.dart';
import '../mappers/turn_mapper.dart';
import '../services/http_client_service.dart';
import '../services/network_config.dart';
import '../services/network_exception.dart';
import '../../domain/models/game_models.dart';
import 'turn_repository.dart';

/// Implementation of TurnRepository using HTTP client
class TurnRepositoryImpl implements TurnRepository {
  final HttpClientService _httpClient;

  TurnRepositoryImpl({required HttpClientService httpClient})
      : _httpClient = httpClient;

  @override
  Future<TurnResult> submitTurn(TurnRequestDto request) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        NetworkConfig.turnEndpoint,
        data: request.toJson(),
        timeout: NetworkConfig.turnSubmissionTimeout,
      );

      // Parse response as TurnAuthoritativeResponseDto
      final responseDto = TurnAuthoritativeResponseDto.fromJson(response);

      // Check response status and handle appropriately
      if (responseDto.status == 'CLARIFICATION_REQUIRED') {
        throw ClarificationRequiredException(
          prompt:
              responseDto.clarificationPrompt ?? 'Please clarify your action',
          clientTurnIdForRetry: request.clientTurnId,
          clarificationContext: responseDto.clarificationContext ?? {},
          message: responseDto.errorMessage,
        );
      }

      if (responseDto.status == 'IDEMPOTENCY_CONFLICT') {
        throw IdempotencyConflictException(
          clientTurnId: request.clientTurnId,
          originalRequestHash: responseDto.requestHash ?? '',
          incomingRequestHash: request.toJson().toString().hashCode.toString(),
        );
      }

      if (responseDto.status == 'CONFLICT') {
        throw SafeRejectException(
          errorCode: 'CONFLICT',
          message:
              'Action conflicts with server state. Please try again.',
          context: {'original_hash': responseDto.conflictOriginalHash},
          retryAllowed: true,
        );
      }

      if (responseDto.status == 'SAFE_REJECT') {
        throw SafeRejectException(
          errorCode: responseDto.errorCode ?? 'UNKNOWN',
          message:
              responseDto.errorMessage ?? 'Action cannot proceed',
          retryAllowed: false,
        );
      }

      // Status should be ACCEPTED at this point
      if (responseDto.status != 'ACCEPTED') {
        throw SafeRejectException(
          errorCode: 'UNKNOWN_STATUS',
          message: 'Unknown turn status: ${responseDto.status}',
        );
      }

      // Convert DTO to domain model
      return TurnMapper.toTurnResult(responseDto);
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error submitting turn: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<TurnResult> submitTurnWithClarification(
    String clientTurnId,
    String clarificationAnswer,
  ) async {
    try {
      // Create a new request with clarification answer
      final request = TurnRequestDto(
        clientTurnId: clientTurnId,
        runId: '', // Would normally come from context
        saveSlotId: '',
        action: '',
        sceneFingerprint: '',
        clarificationAnswer: clarificationAnswer,
      );

      return submitTurn(request);
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error submitting clarification: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRevisionHistory(String runId) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        '${NetworkConfig.turnEndpoint}/$runId/revisions',
      );

      // Parse revision list from response
      final revisions = (response['revisions'] as List?)
              ?.cast<Map<String, dynamic>>()
              .toList() ??
          [];

      return revisions;
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error fetching revision history: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

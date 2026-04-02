import '../dto/rollback_dto.dart';
import '../services/http_client_interface.dart';
import '../services/network_config.dart';
import '../services/network_exception.dart';
import 'rollback_repository.dart';

/// Implementation of RollbackRepository using HTTP client
class RollbackRepositoryImpl implements RollbackRepository {
  final HttpClientServiceInterface _httpClient;

  RollbackRepositoryImpl({required HttpClientServiceInterface httpClient})
      : _httpClient = httpClient;

  @override
  Future<Map<String, dynamic>> rollbackToRevision(
      String revisionId) async {
    try {
      final request = RollbackRequestDto(
        runId: '', // Would normally come from context
        saveSlotId: '',
        revisionId: revisionId,
      );

      final response = await _httpClient.post<Map<String, dynamic>>(
        NetworkConfig.rollbackEndpoint,
        data: request.toJson(),
      );

      final responseDto = RollbackResponseDto.fromJson(response);

      if (!responseDto.success) {
        throw SafeRejectException(
          errorCode: 'ROLLBACK_FAILED',
          message: responseDto.message ?? 'Rollback operation failed',
        );
      }

      // Return game state as map
      return {
        'revision_id': responseDto.revisionId,
        'character_state': responseDto.characterState?.toJson() ?? {},
        'game_state': responseDto.gameState ?? {},
        'revisions_removed': responseDto.revisionsRemoved,
      };
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      throw UnknownNetworkException(
        message: 'Error rolling back to revision: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<RevisionHistoryDto>> getRevisionHistory(String runId) async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        '${NetworkConfig.rollbackEndpoint}/$runId/history',
      );

      final revisionListDto = RevisionListDto.fromJson(response);
      return revisionListDto.revisions;
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

  @override
  Future<bool> canRollbackToRevision(String revisionId) async {
    try {
      final revisions = await getRevisionHistory(''); // Would come from context
      return revisions
          .any((rev) => rev.revisionId == revisionId && rev.rollbackable == true);
    } catch (e) {
      return false;
    }
  }
}

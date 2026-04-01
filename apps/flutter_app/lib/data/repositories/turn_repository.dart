import '../dto/turn_dto.dart';
import '../../domain/models/game_models.dart';

/// Repository interface for turn submission and management
abstract class TurnRepository {
  /// Submit a turn action to the backend
  /// 
  /// Throws [ClarificationRequiredException] if player clarification is needed
  /// Throws [IdempotencyConflictException] if same client_turn_id with different payload
  /// Throws [SafeRejectException] if backend policy rejects the action
  /// Throws [NetworkException] on network failures
  Future<TurnResult> submitTurn(TurnRequestDto request);

  /// Resubmit a turn with clarification answer
  Future<TurnResult> submitTurnWithClarification(
    String clientTurnId,
    String clarificationAnswer,
  );

  /// Get revision history for rollback selection
  Future<List<Map<String, dynamic>>> getRevisionHistory(String runId);
}

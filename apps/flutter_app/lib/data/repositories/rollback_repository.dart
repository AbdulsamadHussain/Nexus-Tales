import '../dto/rollback_dto.dart';
import '../../domain/models/game_models.dart';

/// Repository interface for rollback operations
abstract class RollbackRepository {
  /// Rollback game to a specific revision atomically
  /// 
  /// Throws [RollbackForbiddenException] if revision is not rollback-safe
  /// Throws [NetworkException] on network failures
  /// Returns the restored game state
  Future<Map<String, dynamic>> rollbackToRevision(String revisionId);

  /// Get list of available revisions for this game
  Future<List<RevisionHistoryDto>> getRevisionHistory(String runId);

  /// Check if a revision is rollback-eligible
  Future<bool> canRollbackToRevision(String revisionId);
}

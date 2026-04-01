import '../../domain/models/game_models.dart';
import '../dto/turn_dto.dart';
import '../dto/common_dto.dart';

/// Mapper for turn-related DTOs to domain models

class TurnMapper {
  /// Convert TurnAuthoritativeResponseDto to TurnResult domain model
  static TurnResult toTurnResult(TurnAuthoritativeResponseDto dto) {
    return TurnResult(
      revisionId: dto.revisionId ?? 'unknown',
      actionSummary: _buildActionSummary(dto),
      canonicalEvents: _extractEventDescriptions(dto.simulationResult),
      authorityVersion: 1,
      committedAt: DateTime.now(),
      stateDelta: _buildStateDelta(dto.characterStateDelta),
      narrativeBlocks: _buildNarrativeBlocks(dto.simulationResult),
      sceneSuggestion: '',
    );
  }

  /// Build user-readable action summary from simulation result
  static String _buildActionSummary(TurnAuthoritativeResponseDto dto) {
    if (dto.simulationResult == null) {
      return 'Action processed.';
    }

    final outcome = dto.simulationResult!.actionOutcome;
    return switch (outcome) {
      'SUCCESS' =>
        'Your action succeeded! The story unfolds as intended.',
      'PARTIAL' =>
        'Your action had mixed results. Some parts succeeded, others less so.',
      'FAILURE' =>
        'Your action failed to achieve its goal.',
      _ => 'Action resolved.',
    };
  }

  /// Extract event descriptions as strings from canonical events
  static List<String> _extractEventDescriptions(
      SimulationResultDto? simResult) {
    if (simResult == null || simResult.canonicalEvents == null) {
      return [];
    }

    return simResult.canonicalEvents!
        .map((event) => event.description)
        .toList();
  }

  /// Build narrative blocks from simulation consequences
  static List<String> _buildNarrativeBlocks(SimulationResultDto? simResult) {
    if (simResult == null) return [];

    final blocks = <String>[];

    // Add consequences as narrative text
    if (simResult.consequences != null) {
      blocks.addAll(
        simResult.consequences!.map((c) => '• $c').toList(),
      );
    }

    // Add event descriptions
    if (simResult.canonicalEvents != null) {
      for (final event in simResult.canonicalEvents!) {
        // Build a narrative sentence for each event
        final narrative = _buildEventNarrative(event);
        if (narrative.isNotEmpty) {
          blocks.add(narrative);
        }
      }
    }

    return blocks;
  }

  /// Build a narrative description for a canonical event
  static String _buildEventNarrative(CanonicalEventDto event) {
    final buffer = StringBuffer();

    // Start with the description
    buffer.write(event.description);

    // Add roll information if available
    if (event.rollSum != null && event.targetDC != null) {
      final result =
          event.rollSum! >= event.targetDC! ? 'succeeds' : 'fails';
      buffer.write(' (Roll: ${event.rollSum} vs DC ${event.targetDC}, '
          'result $result)');
    }

    return buffer.toString();
  }

  /// Build state delta map from character changes
  static Map<String, dynamic> _buildStateDelta(
      CharacterStateDeltaDto? delta) {
    if (delta == null) return {};

    final changes = <String, dynamic>{};

    if (delta.hpDelta != null) changes['hp_delta'] = delta.hpDelta;
    if (delta.staminaDelta != null) {
      changes['stamina_delta'] = delta.staminaDelta;
    }
    if (delta.manaDelta != null) changes['mana_delta'] = delta.manaDelta;

    if (delta.inventoryAdded != null && delta.inventoryAdded!.isNotEmpty) {
      changes['inventory_added'] = delta.inventoryAdded;
    }

    if (delta.inventoryRemoved != null &&
        delta.inventoryRemoved!.isNotEmpty) {
      changes['inventory_removed'] = delta.inventoryRemoved;
    }

    if (delta.questUpdates != null && delta.questUpdates!.isNotEmpty) {
      changes['quest_updates'] = delta.questUpdates;
    }

    if (delta.relationshipChanges != null &&
        delta.relationshipChanges!.isNotEmpty) {
      changes['relationship_changes'] = delta.relationshipChanges;
    }

    if (delta.factionChanges != null && delta.factionChanges!.isNotEmpty) {
      changes['faction_changes'] = delta.factionChanges;
    }

    return changes;
  }
}

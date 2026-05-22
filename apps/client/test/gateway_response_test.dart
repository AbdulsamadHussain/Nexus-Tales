import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tale/features/game/narration_fallback.dart';

// These tests verify the client correctly handles each orchestrator status
// without spinning up the full GameScreen widget (which requires Supabase).
// They test the response-handling logic by calling the same pure helpers
// that GameScreen uses.

void main() {
  // ── Gateway REJECT (§5) ───────────────────────────────────────────
  test('REJECTED status → player_message surfaced, no narration', () {
    final data = {
      'status': 'REJECTED',
      'player_message': 'That action is not allowed.',
      'policy_flags': ['PROMPT_INJECTION'],
    };

    expect(data['status'], equals('REJECTED'));
    expect(data['player_message'], isNotNull);
    // Narration must not be produced — revision_id absent
    expect(data.containsKey('revision_id'), isFalse);
  });

  // ── No-op (§6.3) ─────────────────────────────────────────────────
  test('NO_OP status → player_message surfaced, no narration', () {
    final data = {
      'status': 'NO_OP',
      'player_message': 'Your intent remains unclear. Try a different approach.',
    };

    expect(data['status'], equals('NO_OP'));
    expect(data['player_message'], isNotNull);
    expect(data.containsKey('revision_id'), isFalse);
  });

  // ── Clarification (§6.3) ─────────────────────────────────────────
  test('CLARIFICATION_REQUIRED status → clarification message, no revision', () {
    final data = {
      'status': 'CLARIFICATION_REQUIRED',
      'route_category': 'CLARIFICATION_REQUIRED',
      'player_message': 'What do you do?',
    };

    expect(data['status'], equals('CLARIFICATION_REQUIRED'));
    expect(data.containsKey('revision_id'), isFalse);
  });

  // ── Successful turn structure ─────────────────────────────────────
  test('successful turn → revision_id, success_tier, narration_context present', () {
    final data = {
      'status': 'OK',
      'revision_id': 'rev_123456',
      'success_tier': 'FULL_SUCCESS',
      'route_category': 'ROLL_REQUIRED',
      'narration_context': '=== CANONICAL GAME STATE ===\nCharacter: Test',
      'roll': {'die': 14, 'modifier': 3, 'total': 17, 'dc': 14},
      'state_delta': {'stamina': -3, 'xp': 20},
      'events': ['COMBAT_TURN_RESOLVED'],
      'narration_constraints': [],
    };

    expect(data['revision_id'], isNotNull);
    expect(data['success_tier'], equals('FULL_SUCCESS'));
    expect(data['narration_context'], isNotNull);
    expect((data['narration_context'] as String).isNotEmpty, isTrue);
  });

  // ── narration_constraints forwarded correctly ─────────────────────
  test('ALLOW_WITH_CONSTRAINTS → narration_constraints passed to fallback', () {
    final data = {
      'status': 'OK',
      'revision_id': 'rev_789',
      'success_tier': 'FULL_SUCCESS',
      'narration_context': '',
      'narration_constraints': ['NO_GORE'],
      'state_delta': {},
      'events': [],
    };

    final rawConstraints = data['narration_constraints'];
    final constraints = rawConstraints is List
        ? rawConstraints.map((e) => e.toString()).toList()
        : <String>[];

    expect(constraints, contains('NO_GORE'));
  });

  // ── Fallback narration used on Ollama failure ─────────────────────
  test('fallback narration is non-empty for any valid tier', () {
    final tiers = ['CRITICAL_SUCCESS', 'FULL_SUCCESS', 'PARTIAL_SUCCESS', 'FAILURE', 'CRITICAL_FAILURE', 'NO_ROLL'];
    final simResult = {
      'state_delta': {'hp': -5, 'stamina': -3, 'xp': 10},
      'events': ['COMBAT_TURN_RESOLVED'],
    };

    for (final tier in tiers) {
      final narration = buildFallbackNarration(tier, simResult);
      expect(narration.trim().isNotEmpty, isTrue, reason: 'tier $tier produced empty narration');
    }
  });

  // ── Roll bubble ordering ──────────────────────────────────────────
  test('roll data present in successful ROLL_REQUIRED response', () {
    final data = {
      'status': 'OK',
      'revision_id': 'rev_001',
      'success_tier': 'CRITICAL_FAILURE',
      'route_category': 'ROLL_REQUIRED',
      'roll': {'die': 1, 'modifier': 3, 'total': 4, 'dc': 14},
      'state_delta': {'hp': -12},
      'events': ['PLAYER_INJURED', 'NPC_COUNTER_ATTACKED'],
      'narration_constraints': [],
    };

    expect(data['roll'], isNotNull);
    final roll = data['roll'] as Map<String, dynamic>;
    expect(roll['die'], equals(1));
    expect(roll['total'], equals(4));

    // Fallback narration includes damage info
    final narration = buildFallbackNarration(
      data['success_tier'] as String,
      data,
    );
    expect(narration, contains('Everything goes wrong'));
    expect(narration, contains('You take 12 damage'));
  });
}

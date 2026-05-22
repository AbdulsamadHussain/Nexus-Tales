import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tale/features/game/narration_fallback.dart';

void main() {
  // ── Every tier produces a non-empty string ───────────────────────
  for (final tier in ['CRITICAL_SUCCESS', 'FULL_SUCCESS', 'PARTIAL_SUCCESS', 'FAILURE', 'CRITICAL_FAILURE', 'NO_ROLL']) {
    test('tier $tier produces non-empty string', () {
      final result = buildFallbackNarration(tier, {});
      expect(result.trim().isNotEmpty, isTrue);
    });
  }

  // ── Outcome sentences ────────────────────────────────────────────
  test('CRITICAL_SUCCESS → exceptional precision', () {
    expect(buildFallbackNarration('CRITICAL_SUCCESS', {}), contains('exceptional precision'));
  });

  test('FULL_SUCCESS → The attempt succeeds', () {
    expect(buildFallbackNarration('FULL_SUCCESS', {}), contains('The attempt succeeds'));
  });

  test('PARTIAL_SUCCESS → partly succeed', () {
    expect(buildFallbackNarration('PARTIAL_SUCCESS', {}), contains('partly succeed'));
  });

  test('FAILURE → The attempt fails', () {
    expect(buildFallbackNarration('FAILURE', {}), contains('The attempt fails'));
  });

  test('CRITICAL_FAILURE → Everything goes wrong', () {
    expect(buildFallbackNarration('CRITICAL_FAILURE', {}), contains('Everything goes wrong'));
  });

  test('NO_ROLL → The moment passes', () {
    expect(buildFallbackNarration('NO_ROLL', {}), contains('The moment passes'));
  });

  // ── HP delta ─────────────────────────────────────────────────────
  test('hp -8 → You take 8 damage', () {
    final result = buildFallbackNarration('FAILURE', {'state_delta': {'hp': -8}});
    expect(result, contains('You take 8 damage'));
  });

  test('hp +12 → You recover 12 health', () {
    final result = buildFallbackNarration('FULL_SUCCESS', {'state_delta': {'hp': 12}});
    expect(result, contains('You recover 12 health'));
  });

  // ── Stamina ──────────────────────────────────────────────────────
  test('stamina -3 → You spend 3 stamina', () {
    final result = buildFallbackNarration('PARTIAL_SUCCESS', {'state_delta': {'stamina': -3}});
    expect(result, contains('You spend 3 stamina'));
  });

  test('positive stamina not mentioned', () {
    final result = buildFallbackNarration('NO_ROLL', {'state_delta': {'stamina': 8}});
    expect(result, isNot(contains('stamina')));
  });

  // ── XP ───────────────────────────────────────────────────────────
  test('xp +10 → You gain 10 experience', () {
    final result = buildFallbackNarration('PARTIAL_SUCCESS', {'state_delta': {'xp': 10}});
    expect(result, contains('You gain 10 experience'));
  });

  // ── Events ───────────────────────────────────────────────────────
  test('NPC_DEFEATED → The enemy falls', () {
    final result = buildFallbackNarration('FULL_SUCCESS', {'events': ['NPC_DEFEATED']});
    expect(result, contains('The enemy falls'));
  });

  test('NPC_COUNTER_ATTACKED → The enemy strikes back', () {
    final result = buildFallbackNarration('FAILURE', {'events': ['NPC_COUNTER_ATTACKED']});
    expect(result, contains('The enemy strikes back'));
  });

  test('QUEST_UPDATED → Your quest advances', () {
    final result = buildFallbackNarration('FULL_SUCCESS', {'events': ['QUEST_UPDATED']});
    expect(result, contains('Your quest advances'));
  });

  test('RELATIONSHIP_TIER_CHANGED → Your relationship with them shifts', () {
    final result = buildFallbackNarration('NO_ROLL', {
      'events': ['RELATIONSHIP_TIER_CHANGED:npc_mira:Warm'],
    });
    expect(result, contains('Your relationship with them shifts'));
  });

  // ── Combined (§11.1 example from architecture doc) ───────────────
  test('FAILURE + hp -8 + NPC_COUNTER_ATTACKED → full combined prose', () {
    final result = buildFallbackNarration('FAILURE', {
      'state_delta': {'hp': -8},
      'events': ['NPC_COUNTER_ATTACKED'],
    });
    expect(result, contains('The attempt fails'));
    expect(result, contains('You take 8 damage'));
    expect(result, contains('The enemy strikes back'));
  });

  test('CRITICAL_SUCCESS + NPC_DEFEATED + xp 30 → full combined prose', () {
    final result = buildFallbackNarration('CRITICAL_SUCCESS', {
      'state_delta': {'xp': 30},
      'events': ['COMBAT_TURN_RESOLVED', 'NPC_DEFEATED'],
    });
    expect(result, contains('exceptional precision'));
    expect(result, contains('You gain 30 experience'));
    expect(result, contains('The enemy falls'));
  });

  test('NO_ROLL + empty delta + no events → only default sentence', () {
    final result = buildFallbackNarration('NO_ROLL', {'state_delta': {}, 'events': []});
    expect(result, equals('The moment passes.'));
  });
}

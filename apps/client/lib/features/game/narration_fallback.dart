// §11.1 — Code-template narration fallback.
// Extracted as a pure function so it can be unit tested without Flutter deps.
String buildFallbackNarration(String tier, Map<String, dynamic> data) {
  final delta = (data['state_delta'] as Map?)?.cast<String, dynamic>() ?? {};
  final events = (data['events'] as List<dynamic>?)?.cast<String>() ?? [];
  final parts = <String>[];

  switch (tier) {
    case 'CRITICAL_SUCCESS':
      parts.add('You act with exceptional precision.');
    case 'FULL_SUCCESS':
      parts.add('The attempt succeeds.');
    case 'PARTIAL_SUCCESS':
      parts.add('You partly succeed, but not without cost.');
    case 'FAILURE':
      parts.add('The attempt fails.');
    case 'CRITICAL_FAILURE':
      parts.add('Everything goes wrong.');
    default:
      parts.add('The moment passes.');
  }

  final hp = delta['hp'] as int?;
  if (hp != null && hp < 0) parts.add('You take ${hp.abs()} damage.');
  if (hp != null && hp > 0) parts.add('You recover $hp health.');

  final stamina = delta['stamina'] as int?;
  if (stamina != null && stamina < 0) {
    parts.add('You spend ${stamina.abs()} stamina.');
  }

  final xp = delta['xp'] as int?;
  if (xp != null && xp > 0) parts.add('You gain $xp experience.');

  if (events.contains('NPC_DEFEATED')) parts.add('The enemy falls.');
  if (events.contains('NPC_COUNTER_ATTACKED')) parts.add('The enemy strikes back.');
  if (events.any((e) => e.startsWith('QUEST_UPDATED'))) parts.add('Your quest advances.');
  if (events.any((e) => e.startsWith('RELATIONSHIP_TIER_CHANGED'))) {
    parts.add('Your relationship with them shifts.');
  }
  if (events.any((e) => e.startsWith('LEVEL_UP'))) {
    parts.add('You feel your power grow.');
  }
  for (final event in events) {
    final e = event.toString();
    if (e.startsWith('HOSTILE_AGGRESSION:')) {
      final npcName = e.split(':').last;
      parts.add('$npcName attacks you unprovoked.');
    }
  }

  return parts.join(' ');
}

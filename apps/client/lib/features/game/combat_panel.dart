import 'package:flutter/material.dart';

class CombatPanel extends StatelessWidget {
  final List<Map<String, dynamic>> npcsInScene;
  final Map<String, dynamic> npcStates;

  const CombatPanel({
    super.key,
    required this.npcsInScene,
    required this.npcStates,
  });

  @override
  Widget build(BuildContext context) {
    final hostileNpcs = npcsInScene
        .where((n) => n['is_hostile'] == true)
        .toList();

    if (hostileNpcs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3A1A1A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFE05555),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'COMBAT',
                style: TextStyle(
                  color: Color(0xFFE05555),
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...hostileNpcs.map((npc) => _buildNpcRow(npc)),
        ],
      ),
    );
  }

  Widget _buildNpcRow(Map<String, dynamic> npc) {
    final npcId = npc['id'] as String;
    final name = npc['name'] as String;
    final hpMax = npc['hp_max'] as int? ?? 60;

    final state = npcStates[npcId] as Map<String, dynamic>?;
    final currentHp = state?['hp'] as int? ?? hpMax;
    final isDead = state?['is_dead'] as bool? ?? false;
    final pct = (currentHp / hpMax).clamp(0.0, 1.0);

    final hpColor = isDead
        ? const Color(0xFF4A5A72)
        : pct > 0.6
            ? const Color(0xFFE05555)
            : pct > 0.3
                ? const Color(0xFFE09A40)
                : const Color(0xFFFF3333);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isDead
                        ? const Color(0xFF4A5A72)
                        : const Color(0xFFD4DCE8),
                    fontSize: 12,
                    decoration: isDead
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              Text(
                isDead ? 'DEFEATED' : '$currentHp / $hpMax',
                style: TextStyle(
                  color: hpColor,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: isDead ? 0.0 : pct,
              backgroundColor: const Color(0xFF2A1A1A),
              valueColor: AlwaysStoppedAnimation<Color>(hpColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
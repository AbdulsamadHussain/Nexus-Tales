import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CharacterSheetPanel extends StatefulWidget {
  final Map<String, dynamic> canonicalState;
  final VoidCallback onClose;
  final VoidCallback? onSettingChanged;
  final Map<String, dynamic> contentSettings;

  const CharacterSheetPanel({
    super.key,
    required this.canonicalState,
    required this.contentSettings,
    required this.onClose,
    this.onSettingChanged,
  });

  @override
  State<CharacterSheetPanel> createState() => _CharacterSheetPanelState();
}

class _CharacterSheetPanelState extends State<CharacterSheetPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _localContentSettings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.canonicalState;

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1219),
        border: Border(left: BorderSide(color: Color(0xFF1A2230))),
      ),
      child: Column(
        children: [
          _buildHeader(s),
          _buildStatBars(s),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(s),
                _buildInventoryTab(s),
                _buildQuestsTab(s),
                _buildRelationsTab(s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A2230))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2230),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF8A6D2E)),
            ),
            child: Center(
              child: Text(
                (s['character_name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFC9A84C),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['character_name'] as String? ?? 'Unknown',
                  style: const TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${s['character_class']} · ${s['origin']}',
                  style: const TextStyle(
                    color: Color(0xFF4A5A72),
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Level ${s['level']} · ${s['xp']} XP',
                  style: const TextStyle(
                    color: Color(0xFF4A5A72),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF4A5A72), size: 18),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildStatBars(Map<String, dynamic> s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A2230))),
      ),
      child: Column(
        children: [
          _statBar(
            'HP',
            s['hp'] as int,
            s['hp_max'] as int,
            const Color(0xFFE05555),
          ),
          const SizedBox(height: 6),
          _statBar(
            'MP',
            s['mp'] as int,
            s['mp_max'] as int,
            const Color(0xFF4A9EFF),
          ),
          const SizedBox(height: 6),
          _statBar(
            'ST',
            s['stamina'] as int,
            s['stamina_max'] as int,
            const Color(0xFF4CAF82),
          ),
        ],
      ),
    );
  }

  Widget _statBar(String label, int current, int max, Color color) {
    final pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 10, letterSpacing: 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFF1A2230),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current/$max',
          style: const TextStyle(
            color: Color(0xFF8898B0),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF4A9EFF),
      unselectedLabelColor: const Color(0xFF4A5A72),
      indicatorColor: const Color(0xFF4A9EFF),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontSize: 10, letterSpacing: 1),
      tabs: const [
        Tab(text: 'STATS'),
        Tab(text: 'INV'),
        Tab(text: 'QUESTS'),
        Tab(text: 'RELATIONS'),
      ],
    );
  }

  // ── STATS TAB ──────────────────────────────────────────────────

  Widget _buildStatsTab(Map<String, dynamic> s) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _sectionTitle('Resources'),
        _statRow('Gold', '${s['gold']} gp', const Color(0xFFC9A84C)),
        _statRow('XP', '${s['xp']}', const Color(0xFF8898B0)),
        _statRow('Level', '${s['level']}', const Color(0xFF8898B0)),
        const SizedBox(height: 12),
        _sectionTitle('Location'),
        _statRow(
          'Scene',
          _formatId(s['current_location'] as String? ?? ''),
          const Color(0xFF8898B0),
        ),
        _statRow(
          'Campaign',
          _formatId(s['campaign_id'] as String? ?? ''),
          const Color(0xFF8898B0),
        ),
        const SizedBox(height: 12),
        _sectionTitle('Content settings'),
        ..._buildContentSettings(
          _localContentSettings ?? widget.contentSettings,
        ),
      ],
    );
  }

  List<Widget> _buildContentSettings(Map<String, dynamic> settings) {
    final violenceOn = settings['violence'] as bool? ?? false;

    Widget settingRow(String key, String label, {double leftPad = 0}) {
      final on = settings[key] as bool? ?? false;
      return Padding(
        padding: EdgeInsets.only(bottom: 5, left: leftPad),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: on ? const Color(0xFF4CAF82) : const Color(0xFF4A5A72),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF8898B0), fontSize: 12),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _toggleContentSetting(key, !on, settings),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: on
                      ? const Color(0xFF4CAF82).withOpacity(0.1)
                      : const Color(0xFF1A2230),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: on
                        ? const Color(0xFF4CAF82).withOpacity(0.4)
                        : const Color(0xFF2D3A4A),
                  ),
                ),
                child: Text(
                  on ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: on
                        ? const Color(0xFF4CAF82)
                        : const Color(0xFF4A5A72),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return [
      settingRow('violence', 'Violence'),
      if (violenceOn) settingRow('graphic', 'Graphic', leftPad: 16),
      settingRow('horror', 'Horror'),
      settingRow('romance', 'Romance'),
      settingRow('mature', 'Mature themes'),
    ];
  }

  Future<void> _toggleContentSetting(
    String key,
    bool newValue,
    Map<String, dynamic> currentSettings,
  ) async {
    final updated = Map<String, dynamic>.from(currentSettings);
    updated[key] = newValue;

    // Update UI immediately
    setState(() => _localContentSettings = updated);

    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client
          .from('user_preferences')
          .update({'content_settings': updated})
          .eq('user_id', user.id);

      widget.onSettingChanged?.call();
    } catch (e) {
      debugPrint('Content setting toggle failed: $e');
      // Revert on failure
      setState(() => _localContentSettings = currentSettings);
    }
  }

  // ── INVENTORY TAB ───────────────────────────────────────────────

  Widget _buildInventoryTab(Map<String, dynamic> s) {
    final inventory = s['inventory'] as List<dynamic>? ?? [];

    if (inventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.backpack_outlined, color: Color(0xFF2D3A4A), size: 32),
            SizedBox(height: 8),
            Text(
              'Inventory empty',
              style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: inventory.length,
      itemBuilder: (context, i) {
        final item = inventory[i] as Map<String, dynamic>;
        return _inventoryItem(item);
      },
    );
  }

  Widget _inventoryItem(Map<String, dynamic> item) {
    final rarity = item['rarity'] as String? ?? 'common';
    final rarityColor =
        {
          'common': const Color(0xFF8898B0),
          'rare': const Color(0xFF4A9EFF),
          'legendary': const Color(0xFFC9A84C),
        }[rarity] ??
        const Color(0xFF8898B0);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2230),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: rarityColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: rarityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String? ?? 'Unknown item',
                  style: TextStyle(color: rarityColor, fontSize: 12),
                ),
                if (item['description'] != null)
                  Text(
                    item['description'] as String,
                    style: const TextStyle(
                      color: Color(0xFF4A5A72),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (item['quantity'] != null && (item['quantity'] as int) > 1)
            Text(
              'x${item['quantity']}',
              style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 10),
            ),
        ],
      ),
    );
  }

  // ── QUESTS TAB ──────────────────────────────────────────────────

  Widget _buildQuestsTab(Map<String, dynamic> s) {
    final questState = s['quest_state'] as Map<String, dynamic>? ?? {};

    if (questState.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.assignment_outlined, color: Color(0xFF2D3A4A), size: 32),
            SizedBox(height: 8),
            Text(
              'No active quests',
              style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: questState.entries.map((e) {
        final quest = e.value as Map<String, dynamic>;
        final status = quest['status'] as String? ?? 'active';
        final statusColor =
            {
              'active': const Color(0xFF4A9EFF),
              'completed': const Color(0xFF4CAF82),
              'failed': const Color(0xFFE05555),
            }[status] ??
            const Color(0xFF8898B0);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2230),
            borderRadius: BorderRadius.circular(5),
            border: Border(left: BorderSide(color: statusColor, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatId(e.key),
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              if (quest['description'] != null) ...[
                const SizedBox(height: 3),
                Text(
                  quest['description'] as String,
                  style: const TextStyle(
                    color: Color(0xFF4A5A72),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── RELATIONS TAB ───────────────────────────────────────────────

  Widget _buildRelationsTab(Map<String, dynamic> s) {
    final relationships = s['relationships'] as Map<String, dynamic>? ?? {};
    final factions = s['factions'] as Map<String, dynamic>? ?? {};

    if (relationships.isEmpty && factions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.people_outline, color: Color(0xFF2D3A4A), size: 32),
            SizedBox(height: 8),
            Text(
              'No known relationships',
              style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (relationships.isNotEmpty) ...[
          _sectionTitle('Characters'),
          ...relationships.entries.map((e) {
            final rel = e.value as Map<String, dynamic>;
            final score = rel['score'] as int? ?? 0;
            final name = rel['name'] as String? ?? e.key;
            return _relationRow(name, score, rel['tier'] as String?);
          }),
          const SizedBox(height: 12),
        ],
        if (factions.isNotEmpty) ...[
          _sectionTitle('Factions'),
          ...factions.entries.map((e) {
            final f = e.value as Map<String, dynamic>;
            final score = f['score'] as int? ?? 0;
            return _relationRow(e.key, score, f['tier'] as String?);
          }),
        ],
      ],
    );
  }

  Widget _relationRow(String name, int score, String? tier) {
    final color = score <= -51
        ? const Color(0xFFE05555)
        : score <= -11
        ? const Color(0xFFE09A40)
        : score <= 10
        ? const Color(0xFF8898B0)
        : score <= 40
        ? const Color(0xFF2DD4BF)
        : score <= 75
        ? const Color(0xFF4A9EFF)
        : const Color(0xFFC9A84C);

    final pct = ((score + 100) / 200).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFD4DCE8),
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                tier ?? _tierLabel(score),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFF1A2230),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4A5A72),
          fontSize: 9,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _formatId(String id) {
    return id.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  String _tierLabel(int score) {
    if (score <= -51) return 'Hostile';
    if (score <= -11) return 'Distrustful';
    if (score <= 10) return 'Neutral';
    if (score <= 40) return 'Warm';
    if (score <= 75) return 'Loyal';
    return 'Devoted';
  }
}

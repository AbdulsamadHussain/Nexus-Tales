import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CharacterSheetPanel extends StatefulWidget {
  final Map<String, dynamic> canonicalState;
  final VoidCallback onClose;
  final VoidCallback? onSettingChanged;
  final Map<String, dynamic> contentSettings;
  /// Called when the player taps "Use" on an inventory item.
  /// The game screen should populate the action field and submit.
  final void Function(String action)? onUseItem;

  const CharacterSheetPanel({
    super.key,
    required this.canonicalState,
    required this.contentSettings,
    required this.onClose,
    this.onSettingChanged,
    this.onUseItem,
  });

  @override
  State<CharacterSheetPanel> createState() => _CharacterSheetPanelState();
}

class _CharacterSheetPanelState extends State<CharacterSheetPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _localContentSettings;
  bool _editingClass = false;
  String? _pendingClass;
  bool _classChangeBusy = false;
  List<Map<String, dynamic>> _npcs = [];

  // Character story editing
  final _nameEditController = TextEditingController();
  final _originEditController = TextEditingController();
  final _backstoryEditController = TextEditingController();
  bool _storyEditBusy = false;

  static const _classes = ['Rogue', 'War Mage', 'Warden', 'Plague Doctor', 'Hex Blade'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadNpcs();
  }

  Future<void> _loadNpcs() async {
    final campaignId = widget.canonicalState['campaign_id'] as String?;
    if (campaignId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('npcs')
          .select('id, name, archetype, role, faction')
          .eq('campaign_id', campaignId);
      if (mounted) {
        setState(() => _npcs = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint('NPC load failed: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameEditController.dispose();
    _originEditController.dispose();
    _backstoryEditController.dispose();
    super.dispose();
  }

  void _openStoryEditor(Map<String, dynamic> s) {
    _nameEditController.text = s['character_name'] as String? ?? '';
    _originEditController.text = s['origin'] as String? ?? '';
    _backstoryEditController.text = s['backstory'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1219),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFF1A2230)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Text('EDIT CHARACTER', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 12, letterSpacing: 2)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF4A5A72), size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
              const SizedBox(height: 16),
              _sheetLabel('Name'),
              _sheetField(_nameEditController, 'Character name'),
              const SizedBox(height: 14),
              _sheetLabel('Origin'),
              _sheetField(_originEditController, 'e.g. Street Rat, Exiled Noble...'),
              const SizedBox(height: 14),
              _sheetLabel('Backstory'),
              _sheetField(_backstoryEditController, 'Who are you, and what drove you here?', maxLines: 4),
              const SizedBox(height: 8),
              const Text(
                'Name and origin shape how the narrator refers to you. Backstory influences tone.',
                style: TextStyle(color: Color(0xFF4A5A72), fontSize: 11),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _storyEditBusy ? null : () async {
                  setSheet(() => _storyEditBusy = true);
                  try {
                    // Profile edits go through canonical_command — server enforces limits
                    await Supabase.instance.client.functions.invoke(
                      'canonical_command',
                      body: {
                        'character_id': widget.canonicalState['character_id'] as String,
                        'command': 'EDIT_PROFILE',
                        'character_name': _nameEditController.text.trim(),
                        'origin': _originEditController.text.trim(),
                        'backstory': _backstoryEditController.text.trim(),
                      },
                    );
                    widget.onSettingChanged?.call();
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setSheet(() => _storyEditBusy = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D7DD2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _storyEditBusy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save changes', style: TextStyle(letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(), style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 10, letterSpacing: 1.5)),
  );

  Widget _sheetField(TextEditingController ctrl, String hint, {int maxLines = 1}) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4A5A72)),
      filled: true,
      fillColor: const Color(0xFF1A2230),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2D3A4A))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2D3A4A))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF4A9EFF))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

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
                _buildCodexTab(s),
                _buildNpcsTab(s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitIcon(Map<String, dynamic> s) {
    final portrait = s['portrait'] as String? ?? 'default';
    final Map<String, (IconData, Color)> portraitMap = {
      'default': (Icons.person, const Color(0xFF4A5A72)),
      'rogue':   (Icons.visibility_off, const Color(0xFF9B59B6)),
      'mage':    (Icons.auto_fix_high, const Color(0xFF4A9EFF)),
      'warrior': (Icons.shield, const Color(0xFF7F8C8D)),
      'doctor':  (Icons.science, const Color(0xFF4CAF82)),
      'hex':     (Icons.hexagon, const Color(0xFFE05555)),
    };
    final (icon, color) = portraitMap[portrait] ?? (Icons.person, const Color(0xFF4A5A72));
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Icon(icon, color: color, size: 22),
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
          _buildPortraitIcon(s),
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
                  '${s['character_class']}',
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
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4A5A72), size: 16),
            tooltip: 'Edit character',
            onPressed: () => _openStoryEditor(s),
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
        Tab(text: 'RELS'),
        Tab(text: 'CODEX'),
        Tab(text: 'NPCS'),
      ],
    );
  }

  // ── STATS TAB ──────────────────────────────────────────────────

  // Returns null if change is allowed, or a human-readable reason string.
  String? _classChangeBlockReason(Map<String, dynamic> s) {
    final raw = s['last_class_change_at'] as String?;
    if (raw == null) return null; // never changed — allowed
    final last = DateTime.tryParse(raw);
    if (last == null) return null;
    final diff = DateTime.now().difference(last);
    if (diff.inDays < 30) {
      final daysLeft = 30 - diff.inDays;
      return 'Available in $daysLeft day${daysLeft == 1 ? '' : 's'}';
    }
    return null;
  }

  Future<void> _confirmClassChange(Map<String, dynamic> s) async {
    if (_pendingClass == null || _classChangeBusy) return;
    setState(() => _classChangeBusy = true);

    try {
      final user = Supabase.instance.client.auth.currentUser!;
      // Recalculate stats for the new class
      final hpMax = _pendingClass == 'Warden' ? 60 : _pendingClass == 'War Mage' ? 28 : 40;
      final mpMax = _pendingClass == 'War Mage' ? 40 : _pendingClass == 'Hex Blade' ? 30 : 20;

      await Supabase.instance.client
          .from('canonical_state')
          .update({
            'character_class': _pendingClass,
            'hp_max': hpMax,
            'hp': (s['hp'] as int).clamp(0, hpMax),
            'mp_max': mpMax,
            'mp': (s['mp'] as int).clamp(0, mpMax),
            'last_class_change_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('character_id', s['character_id'] as String);

      widget.onSettingChanged?.call();
      setState(() {
        _editingClass = false;
        _pendingClass = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _classChangeBusy = false);
    }
  }

  Widget _buildClassEditor(Map<String, dynamic> s) {
    final blockReason = _classChangeBlockReason(s);
    final currentClass = s['character_class'] as String? ?? '';

    if (!_editingClass) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(
              currentClass,
              style: const TextStyle(color: Color(0xFF8898B0), fontSize: 12),
            ),
            const Spacer(),
            if (blockReason != null)
              Text(
                blockReason,
                style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 10),
              )
            else
              GestureDetector(
                onTap: () => setState(() {
                  _editingClass = true;
                  _pendingClass = currentClass;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2230),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2D3A4A)),
                  ),
                  child: const Text(
                    'CHANGE',
                    style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 10, letterSpacing: 1),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Editing mode
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _classes.map((c) {
            final sel = (_pendingClass ?? currentClass) == c;
            return GestureDetector(
              onTap: () => setState(() => _pendingClass = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF0F1A2E) : const Color(0xFF1A2230),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: sel ? const Color(0xFF4A9EFF) : const Color(0xFF2D3A4A),
                  ),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: sel ? const Color(0xFF4A9EFF) : const Color(0xFF8898B0),
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'This can only be changed once every 30 days. HP and MP max will update.',
          style: TextStyle(color: Color(0xFF4A5A72), fontSize: 10, height: 1.4),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _editingClass = false;
                  _pendingClass = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2230),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _classChangeBusy ? null : () => _confirmClassChange(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1A2E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF4A9EFF).withValues(alpha: 0.5)),
                  ),
                  child: _classChangeBusy
                      ? const Center(
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A9EFF)),
                          ),
                        )
                      : const Text(
                          'Confirm',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 12),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatsTab(Map<String, dynamic> s) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _sectionTitle('Character'),
        _buildClassEditor(s),
        const SizedBox(height: 8),
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
          if (item['item_type'] == 'consumable' && widget.onUseItem != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                final itemName = item['name'] as String? ?? 'item';
                widget.onUseItem!('use $itemName');
                widget.onClose(); // close the sheet so player sees the action
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF82).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF4CAF82).withOpacity(0.4)),
                ),
                child: const Text(
                  'USE',
                  style: TextStyle(color: Color(0xFF4CAF82), fontSize: 9, letterSpacing: 1),
                ),
              ),
            ),
          ],
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

  // ── CODEX TAB ───────────────────────────────────────────────────

  Widget _buildCodexTab(Map<String, dynamic> s) {
    final knownLore = s['known_lore'] as List<dynamic>? ?? [];

    if (knownLore.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.book_outlined, color: Color(0xFF2D3A4A), size: 32),
            SizedBox(height: 8),
            Text(
              'No lore discovered yet',
              style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: knownLore.length,
      itemBuilder: (context, i) {
        final raw = knownLore[i];
        return _buildLoreEntry(raw);
      },
    );
  }

  Widget _buildLoreEntry(dynamic raw) {
    Widget content;

    if (raw is String) {
      // Plain string entry
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book, color: Color(0xFF4A5A72), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              raw,
              style: const TextStyle(
                color: Color(0xFF8898B0),
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    } else if (raw is Map<String, dynamic>) {
      if (raw.containsKey('title') && raw.containsKey('content')) {
        // Map with title + content
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              raw['title'] as String? ?? '',
              style: const TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              raw['content'] as String? ?? '',
              style: const TextStyle(
                color: Color(0xFF8898B0),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        );
      } else if (raw.containsKey('entry')) {
        // Map with just 'entry'
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.menu_book, color: Color(0xFF4A5A72), size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                raw['entry'] as String? ?? '',
                style: const TextStyle(
                  color: Color(0xFF8898B0),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      } else {
        // Fallback for maps with title/body/category (legacy format)
        final title = raw['title'] as String? ?? 'Unknown';
        final body = raw['body'] as String? ?? '';
        final category = raw['category'] as String? ?? 'LORE';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF4A5A72),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF8898B0),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        );
      }
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2230),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2D3A4A)),
      ),
      child: content,
    );
  }

  // ── NPCS TAB ────────────────────────────────────────────────────

  Widget _buildNpcsTab(Map<String, dynamic> s) {
    if (_npcs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.groups_outlined, color: Color(0xFF2D3A4A), size: 32),
            SizedBox(height: 8),
            Text(
              'No NPCs encountered yet',
              style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
            ),
          ],
        ),
      );
    }

    final relationships = s['relationships'] as Map<String, dynamic>? ?? {};

    int _relScore(String npcId, String npcName) {
      final byId = relationships[npcId] as Map<String, dynamic>?;
      if (byId != null) return byId['score'] as int? ?? 0;
      final byName = relationships[npcName.toLowerCase().replaceAll(' ', '_')] as Map<String, dynamic>?;
      if (byName != null) return byName['score'] as int? ?? 0;
      return 0;
    }

    final allies = _npcs.where((n) => _relScore(n['id'] as String? ?? '', n['name'] as String? ?? '') > 10).toList();
    final hostile = _npcs.where((n) => _relScore(n['id'] as String? ?? '', n['name'] as String? ?? '') < -10).toList();
    final neutral = _npcs.where((n) {
      final score = _relScore(n['id'] as String? ?? '', n['name'] as String? ?? '');
      return score >= -10 && score <= 10;
    }).toList();

    Widget npcCard(Map<String, dynamic> npc) {
      final id = npc['id'] as String? ?? '';
      final name = npc['name'] as String? ?? 'Unknown';
      final archetype = npc['archetype'] as String? ?? npc['role'] as String? ?? '';
      final faction = npc['faction'] as String? ?? '';
      final score = _relScore(id, name);
      final color = score > 10
          ? const Color(0xFF4CAF82)
          : score < -10
              ? const Color(0xFFE05555)
              : const Color(0xFF8898B0);

      // Disposition badge
      final (badgeLabel, badgeColor) = score > 50
          ? ('Trusted', const Color(0xFF4CAF82))
          : score > 10
              ? ('Friendly', const Color(0xFF2DD4BF))
              : score < -50
                  ? ('Hostile', const Color(0xFFE05555))
                  : ('Neutral', const Color(0xFF4A5A72));

      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2230),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 8, top: 3),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name, style: const TextStyle(color: Color(0xFFD4DCE8), fontSize: 12)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: badgeColor.withOpacity(0.35)),
                        ),
                        child: Text(badgeLabel, style: TextStyle(color: badgeColor, fontSize: 9, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  if (archetype.isNotEmpty || faction.isNotEmpty)
                    Text(
                      [if (archetype.isNotEmpty) archetype, if (faction.isNotEmpty) faction].join(' · '),
                      style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 10),
                    ),
                ],
              ),
            ),
            Text(
              score > 0 ? '+$score' : '$score',
              style: TextStyle(color: color, fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (allies.isNotEmpty) ...[
          _sectionTitle('Allies'),
          ...allies.map(npcCard),
          const SizedBox(height: 12),
        ],
        if (neutral.isNotEmpty) ...[
          _sectionTitle('Neutral'),
          ...neutral.map(npcCard),
          const SizedBox(height: 12),
        ],
        if (hostile.isNotEmpty) ...[
          _sectionTitle('Hostile'),
          ...hostile.map(npcCard),
        ],
      ],
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
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
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

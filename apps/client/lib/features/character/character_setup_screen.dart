import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../game/game_screen.dart';

class CharacterSetupScreen extends StatefulWidget {
  /// If non-null, the character will be placed into this custom campaign
  /// instead of the default campaign_01.
  final Map<String, dynamic>? customCampaign;

  const CharacterSetupScreen({super.key, this.customCampaign});

  @override
  State<CharacterSetupScreen> createState() => _CharacterSetupScreenState();
}

class _CharacterSetupScreenState extends State<CharacterSetupScreen> {
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _backstoryController = TextEditingController();
  bool _busy = false;
  String? _selectedPreset;
  bool _useCustom = false;
  String _selectedClass = 'Rogue';
  String _selectedPortrait = 'default';

  final _presets = [
    {
      'id': 'preset_shadow_rogue',
      'name': 'Seraphyn Vael',
      'class': 'Rogue',
      'origin': 'Street Rat',
      'description': 'A shadow dancer from the Ashroot Quarter. Fast, precise, deadly.',
      'hp_max': 40,
      'mp_max': 20,
      'stamina_max': 20,
    },
    {
      'id': 'preset_war_mage',
      'name': 'Aldric Voss',
      'class': 'War Mage',
      'origin': 'Academy Exile',
      'description': 'A disgraced mage who weaponized forbidden theory. Powerful but fragile.',
      'hp_max': 28,
      'mp_max': 40,
      'stamina_max': 15,
    },
    {
      'id': 'preset_iron_warden',
      'name': 'Bryn Ashfeld',
      'class': 'Warden',
      'origin': 'Fallen Knight',
      'description': 'A former city guard who survived something they refuse to name.',
      'hp_max': 60,
      'mp_max': 10,
      'stamina_max': 30,
    },
  ];

  final _classes = ['Rogue', 'War Mage', 'Warden', 'Plague Doctor', 'Hex Blade'];

  bool get _isCustomCampaign => widget.customCampaign != null;

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _backstoryController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    if (!_useCustom && _selectedPreset == null) return;
    if (_useCustom && _nameController.text.trim().isEmpty) return;
    setState(() => _busy = true);

    try {
      Map<String, dynamic> characterData;

      if (_selectedPreset != null && !_useCustom) {
        final preset = _presets.firstWhere((p) => p['id'] == _selectedPreset);
        characterData = {
          'character_name': preset['name'],
          'character_class': preset['class'],
          'origin': preset['origin'],
          'hp_max': preset['hp_max'],
          'mp_max': preset['mp_max'],
          'stamina_max': preset['stamina_max'],
          'portrait': _selectedPortrait,
        };
      } else {
        final hpMax = _selectedClass == 'Warden' ? 60
            : _selectedClass == 'War Mage' ? 28 : 40;
        final mpMax = _selectedClass == 'War Mage' ? 40
            : _selectedClass == 'Hex Blade' ? 30 : 20;
        characterData = {
          'character_name': _nameController.text.trim(),
          'character_class': _selectedClass,
          'origin': _originController.text.trim().isEmpty ? null : _originController.text.trim(),
          'backstory': _backstoryController.text.trim().isEmpty ? null : _backstoryController.text.trim(),
          'hp_max': hpMax,
          'mp_max': mpMax,
          'stamina_max': 20,
          'portrait': _selectedPortrait,
        };
      }

      // Attach custom campaign payload if coming from CreateCampaignScreen
      if (_isCustomCampaign) {
        characterData['custom_campaign'] = widget.customCampaign;
      }

      final response = await Supabase.instance.client.functions.invoke(
        'create_character',
        body: characterData,
      );
      final result = response.data as Map<String, dynamic>?;
      final characterId = result?['character_id'] as String?;

      if (mounted && characterId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => GameScreen(characterId: characterId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1219),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A9EFF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isCustomCampaign ? 'CHOOSE YOUR CHARACTER' : 'CHOOSE YOUR CHARACTER',
          style: const TextStyle(
            letterSpacing: 3,
            color: Color(0xFFC9A84C),
            fontSize: 14,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isCustomCampaign) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1A2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D7DD2).withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customCampaign!['title'] as String,
                      style: const TextStyle(
                        color: Color(0xFFC9A84C),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Custom world · ${_toneLabel(widget.customCampaign!['narrator_tone'] as String)}',
                      style: const TextStyle(color: Color(0xFF4A9EFF), fontSize: 11, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],

            // Toggle
            Row(
              children: [
                _toggleBtn('Choose preset', !_useCustom, () => setState(() => _useCustom = false)),
                const SizedBox(width: 8),
                _toggleBtn('Create custom', _useCustom, () => setState(() => _useCustom = true)),
              ],
            ),
            const SizedBox(height: 24),

            if (!_useCustom) ...[
              ..._presets.map((preset) => _presetCard(preset)),
            ] else ...[
              _sectionLabel('Character name'),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Enter name...'),
              ),
              const SizedBox(height: 16),
              _sectionLabel('Class'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _classes.map((c) => _chip(
                  c, _selectedClass == c,
                  () => setState(() => _selectedClass = c),
                )).toList(),
              ),
              const SizedBox(height: 16),
              _sectionLabel('Portrait'),
              _buildPortraitPicker(),
              const SizedBox(height: 16),
              _sectionLabel('Origin (optional)'),
              TextField(
                controller: _originController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('e.g. Street Rat, Exiled Noble, War Survivor...'),
              ),
              const SizedBox(height: 16),
              _sectionLabel('Backstory (optional)'),
              TextField(
                controller: _backstoryController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: _inputDecoration('Who are you, and what drove you here?'),
              ),
              const SizedBox(height: 4),
              const Text(
                'These details shape how the narrator describes your character and world.',
                style: TextStyle(color: Color(0xFF4A5A72), fontSize: 11),
              ),
            ],

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _busy ? null : _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7DD2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Begin your story',
                      style: TextStyle(letterSpacing: 1, fontSize: 15),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _toneLabel(String tone) {
    const labels = {
      'grimdark': 'Grimdark',
      'epic': 'Epic Fantasy',
      'horror': 'Cosmic Horror',
      'dark_comedy': 'Dark Comedy',
      'gritty': 'Gritty Realism',
      'mythic': 'Mythic',
    };
    return labels[tone] ?? tone;
  }

  static const _portraits = [
    ('default', Icons.person, Color(0xFF4A5A72)),
    ('rogue', Icons.visibility_off, Color(0xFF9B59B6)),
    ('mage', Icons.auto_fix_high, Color(0xFF4A9EFF)),
    ('warrior', Icons.shield, Color(0xFF7F8C8D)),
    ('doctor', Icons.science, Color(0xFF4CAF82)),
    ('hex', Icons.hexagon, Color(0xFFE05555)),
  ];

  Widget _buildPortraitPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _portraits.map((p) {
        final selected = _selectedPortrait == p.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedPortrait = p.$1),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: selected ? p.$3.withOpacity(0.2) : const Color(0xFF0F1219),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? p.$3 : const Color(0xFF1A2230),
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(p.$2, color: selected ? p.$3 : const Color(0xFF4A5A72), size: 22),
          ),
        );
      }).toList(),
    );
  }

  Widget _presetCard(Map<String, dynamic> preset) {
    final selected = _selectedPreset == preset['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedPreset = preset['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F1A2E) : const Color(0xFF0F1219),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF4A9EFF) : const Color(0xFF1A2230),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        preset['name'] as String,
                        style: const TextStyle(
                          color: Color(0xFFC9A84C),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2230),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          preset['class'] as String,
                          style: const TextStyle(
                            color: Color(0xFF4A9EFF),
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset['description'] as String,
                    style: const TextStyle(color: Color(0xFF8898B0), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statPill('HP', preset['hp_max'] as int, const Color(0xFFE05555)),
                      const SizedBox(width: 6),
                      _statPill('MP', preset['mp_max'] as int, const Color(0xFF4A9EFF)),
                      const SizedBox(width: 6),
                      _statPill('ST', preset['stamina_max'] as int, const Color(0xFF4CAF82)),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF4A9EFF), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(color: color, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1A2230) : const Color(0xFF0F1219),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? const Color(0xFF4A9EFF) : const Color(0xFF1A2230),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? const Color(0xFF4A9EFF) : const Color(0xFF4A5A72),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF4A5A72),
          fontSize: 10,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F1A2E) : const Color(0xFF0F1219),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? const Color(0xFF4A9EFF) : const Color(0xFF1A2230),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF4A9EFF) : const Color(0xFF8898B0),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4A5A72)),
      filled: true,
      fillColor: const Color(0xFF1A2230),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF2D3A4A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF2D3A4A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF4A9EFF)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

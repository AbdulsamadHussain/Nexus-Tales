import 'package:flutter/material.dart';
import '../character/character_setup_screen.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _titleController = TextEditingController();
  final _worldController = TextEditingController();
  final _sceneNameController = TextEditingController();
  final _sceneDescController = TextEditingController();
  final _sceneAtmosphereController = TextEditingController();

  String _narratorTone = 'grimdark';
  bool _isPublic = false;
  bool _busy = false;

  static const _tones = [
    ('grimdark', 'Grimdark', 'Brutal and unforgiving. Moral ambiguity, hard choices, no safe heroes.'),
    ('epic', 'Epic Fantasy', 'Grand stakes, heroic deeds, ancient evils. The world needs saving.'),
    ('horror', 'Cosmic Horror', 'Unknowable forces, dread, madness. Survival is a small victory.'),
    ('dark_comedy', 'Dark Comedy', 'Absurd, sardonic, and bleak. Laugh or cry — probably both.'),
    ('gritty', 'Gritty Realism', 'Low fantasy, political intrigue, survival. No chosen ones here.'),
    ('mythic', 'Mythic', 'Legendary in scope. Gods, fate, and heroes of impossible stature.'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _worldController.dispose();
    _sceneNameController.dispose();
    _sceneDescController.dispose();
    _sceneAtmosphereController.dispose();
    super.dispose();
  }

  bool get _valid =>
      _titleController.text.trim().isNotEmpty &&
      _worldController.text.trim().isNotEmpty &&
      _sceneNameController.text.trim().isNotEmpty &&
      _sceneDescController.text.trim().isNotEmpty;

  void _proceed() {
    if (!_valid || _busy) return;
    // Pass campaign data to character setup
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CharacterSetupScreen(
        customCampaign: {
          'title': _titleController.text.trim(),
          'world_description': _worldController.text.trim(),
          'narrator_tone': _narratorTone,
          'starting_scene_title': _sceneNameController.text.trim(),
          'starting_scene_description': _sceneDescController.text.trim(),
          'starting_scene_atmosphere': _sceneAtmosphereController.text.trim().isEmpty
              ? _worldController.text.trim()
              : _sceneAtmosphereController.text.trim(),
          'is_public': _isPublic,
        },
      ),
    ));
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
        title: const Text(
          'CREATE YOUR WORLD',
          style: TextStyle(
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
            _sectionLabel('World name'),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('e.g. The Shattered Dominion'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            _sectionLabel('World description'),
            const Text(
              'Describe your world — its history, tone, factions, and what makes it unique. '
              'This becomes your narrator\'s bible.',
              style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _worldController,
              style: const TextStyle(color: Colors.white, height: 1.5),
              maxLines: 5,
              decoration: _inputDecoration(
                'e.g. A continent shattered by a war between gods. The survivors built empires on the ruins, '
                'each believing their god was the one who sacrificed everything to end it...',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Narrator tone'),
            const Text(
              'The voice your world speaks in.',
              style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
            ),
            const SizedBox(height: 10),
            ..._tones.map((t) => _toneCard(t.$1, t.$2, t.$3)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MAKE WORLD PUBLIC', style: TextStyle(color: Color(0xFF4A5A72), fontSize: 10, letterSpacing: 1.5)),
                      const SizedBox(height: 2),
                      const Text('Other players can discover and play your world', style: TextStyle(color: Color(0xFF4A5A72), fontSize: 10)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isPublic = !_isPublic),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isPublic ? const Color(0xFF4CAF82).withOpacity(0.1) : const Color(0xFF1A2230),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _isPublic ? const Color(0xFF4CAF82) : const Color(0xFF2D3A4A)),
                    ),
                    child: Text(_isPublic ? 'ON' : 'OFF', style: TextStyle(color: _isPublic ? const Color(0xFF4CAF82) : const Color(0xFF4A5A72), fontSize: 11, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionLabel('Starting scene'),
            TextField(
              controller: _sceneNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Scene name — e.g. The Collapsed Gate'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sceneDescController,
              style: const TextStyle(color: Colors.white, height: 1.5),
              maxLines: 3,
              decoration: _inputDecoration(
                'What does the player see, hear, smell? What is immediately present?',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _sectionLabel('Narrator atmosphere (optional)'),
            TextField(
              controller: _sceneAtmosphereController,
              style: const TextStyle(color: Colors.white, height: 1.5),
              maxLines: 2,
              decoration: _inputDecoration(
                'Instructions for how this scene should feel — e.g. "Tense, uncertain. '
                'Something watches from the dark. Describe shadows and silence."',
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _valid && !_busy ? _proceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _valid ? const Color(0xFF2D7DD2) : const Color(0xFF1A2230),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                'Choose your character',
                style: TextStyle(
                  letterSpacing: 1,
                  fontSize: 15,
                  color: _valid ? Colors.white : const Color(0xFF4A5A72),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _toneCard(String value, String label, String description) {
    final selected = _narratorTone == value;
    return GestureDetector(
      onTap: () => setState(() => _narratorTone = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? const Color(0xFF4A9EFF) : const Color(0xFFC9A84C),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF4A9EFF), size: 18),
          ],
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF2D3A4A), fontSize: 12),
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

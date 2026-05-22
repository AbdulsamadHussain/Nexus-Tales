import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../campaign/browse_campaigns_screen.dart';
import '../campaign/create_campaign_screen.dart';
import '../game/game_screen.dart';
import 'character_setup_screen.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  List<Map<String, dynamic>> _characters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final data = await Supabase.instance.client
        .from('canonical_state')
        .select('character_id, character_name, character_class, level, xp, campaign_id, portrait, updated_at')
        .eq('user_id', user.id)
        .order('updated_at', ascending: false);
    if (mounted) setState(() { _characters = List<Map<String, dynamic>>.from(data); _loading = false; });
  }

  Future<void> _deleteCharacter(String characterId, String? campaignId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1219),
        title: const Text('Delete character?', style: TextStyle(color: Color(0xFFC9A84C))),
        content: const Text('This cannot be undone.', style: TextStyle(color: Color(0xFF8898B0))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF4A5A72)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFE05555)))),
        ],
      ),
    );
    if (confirmed != true) return;

    await Supabase.instance.client
        .from('canonical_state')
        .delete()
        .eq('character_id', characterId);

    if (campaignId != null && campaignId.startsWith('custom_')) {
      await Supabase.instance.client
          .from('campaigns')
          .delete()
          .eq('id', campaignId);
    }
    _loadCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1219),
        title: const Text('YOUR CHARACTERS', style: TextStyle(letterSpacing: 3, color: Color(0xFFC9A84C), fontSize: 13)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF4A5A72), size: 18),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9EFF)))
          : Column(
              children: [
                Expanded(
                  child: _characters.isEmpty
                      ? const Center(child: Text('No characters yet.', style: TextStyle(color: Color(0xFF4A5A72))))
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _characters.length,
                          itemBuilder: (context, i) => _characterCard(_characters[i]),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CharacterSetupScreen()),
                        ).then((_) => _loadCharacters()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2230),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Color(0xFF2D7DD2)),
                          ),
                        ),
                        child: const Text('+ New Character', style: TextStyle(color: Color(0xFF4A9EFF), letterSpacing: 1)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreateCampaignScreen()),
                        ).then((_) => _loadCharacters()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F1219),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Color(0xFF4A5A72)),
                          ),
                        ),
                        child: const Text('+ Create Custom World', style: TextStyle(color: Color(0xFF8898B0), letterSpacing: 1)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BrowseCampaignsScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F1219),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: Color(0xFF8A6D2E)),
                          ),
                        ),
                        child: const Text('⚔  Browse Worlds', style: TextStyle(color: Color(0xFFC9A84C), letterSpacing: 1, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _portraitIcon(Map<String, dynamic> c) {
    final portrait = c['portrait'] as String? ?? 'default';
    const portraitMap = <String, (IconData, Color)>{
      'default': (Icons.person, Color(0xFF4A5A72)),
      'rogue':   (Icons.visibility_off, Color(0xFF9B59B6)),
      'mage':    (Icons.auto_fix_high, Color(0xFF4A9EFF)),
      'warrior': (Icons.shield, Color(0xFF7F8C8D)),
      'doctor':  (Icons.science, Color(0xFF4CAF82)),
      'hex':     (Icons.hexagon, Color(0xFFE05555)),
    };
    final entry = portraitMap[portrait] ?? (Icons.person, const Color(0xFF4A5A72));
    final icon = entry.$1;
    final color = entry.$2;
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

  Widget _characterCard(Map<String, dynamic> c) {
    final characterId = c['character_id'] as String;
    final campaignId = c['campaign_id'] as String?;
    final isCustom = campaignId?.startsWith('custom_') ?? false;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GameScreen(characterId: characterId)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1219),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1A2230)),
        ),
        child: Row(
          children: [
            _portraitIcon(c),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['character_name'] as String? ?? 'Unknown',
                      style: const TextStyle(color: Color(0xFFC9A84C), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('${c['character_class']} · Level ${c['level']}',
                      style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 11)),
                  if (isCustom)
                    const Text('Custom world', style: TextStyle(color: Color(0xFF2D7DD2), fontSize: 10)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF4A5A72), size: 18),
              onPressed: () => _deleteCharacter(characterId, campaignId),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF4A5A72), size: 20),
          ],
        ),
      ),
    );
  }
}

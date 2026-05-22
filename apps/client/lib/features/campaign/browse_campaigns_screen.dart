import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../character/character_setup_screen.dart';

class BrowseCampaignsScreen extends StatefulWidget {
  const BrowseCampaignsScreen({super.key});

  @override
  State<BrowseCampaignsScreen> createState() => _BrowseCampaignsScreenState();
}

class _BrowseCampaignsScreenState extends State<BrowseCampaignsScreen> {
  List<Map<String, dynamic>> _campaigns = [];
  bool _loading = true;
  String _selectedTone = 'all';
  String? _error;

  static const _toneFilters = [
    ('all', 'All'),
    ('grimdark', 'Grimdark'),
    ('epic', 'Epic'),
    ('horror', 'Horror'),
    ('dark_comedy', 'Comedy'),
    ('gritty', 'Gritty'),
    ('mythic', 'Mythic'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _loading = true);
    try {
      var query = Supabase.instance.client
          .from('campaigns')
          .select('id, title, description, narrator_tone, world_description, user_id')
          .eq('is_public', true)
          .eq('is_custom', true);
      if (_selectedTone != 'all') {
        query = query.eq('narrator_tone', _selectedTone);
      }
      final data = await query.order('created_at', ascending: false).limit(30);
      if (mounted) setState(() { _campaigns = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('BROWSE WORLDS', style: TextStyle(letterSpacing: 3, color: Color(0xFFC9A84C), fontSize: 13)),
      ),
      body: Column(
        children: [
          // Tone filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _toneFilters.map((f) {
                final selected = _selectedTone == f.$1;
                return GestureDetector(
                  onTap: () { setState(() => _selectedTone = f.$1); _loadCampaigns(); },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1A2230) : const Color(0xFF0F1219),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? const Color(0xFF4A9EFF) : const Color(0xFF1A2230)),
                    ),
                    child: Text(f.$2, style: TextStyle(color: selected ? const Color(0xFF4A9EFF) : const Color(0xFF4A5A72), fontSize: 11)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9EFF)))
                : _error != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Error: $_error', style: const TextStyle(color: Color(0xFFE05555), fontSize: 12)),
                      ))
                : _campaigns.isEmpty
                    ? const Center(child: Text('No public worlds yet.\nCreate one and mark it public!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF4A5A72), fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _campaigns.length,
                        itemBuilder: (_, i) => _campaignCard(_campaigns[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _campaignCard(Map<String, dynamic> c) {
    final toneColors = {
      'grimdark': const Color(0xFF8898B0),
      'epic': const Color(0xFFC9A84C),
      'horror': const Color(0xFF9B59B6),
      'dark_comedy': const Color(0xFF4CAF82),
      'gritty': const Color(0xFFE05555),
      'mythic': const Color(0xFF4A9EFF),
    };
    final tone = c['narrator_tone'] as String? ?? 'grimdark';
    final toneColor = toneColors[tone] ?? const Color(0xFF8898B0);
    final toneLabel = tone.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

    return GestureDetector(
      onTap: () {
        // Pass the existing campaign id — create_character will join it server-side
        // without duplicating campaign rows or scenes.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CharacterSetupScreen(
              existingCampaignId: c['id'] as String,
              existingCampaignDisplay: {
                'title': c['title'] as String? ?? 'Unknown World',
                'narrator_tone': tone,
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1219),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1A2230)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c['title'] as String? ?? 'Untitled', style: const TextStyle(color: Color(0xFFC9A84C), fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: toneColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: toneColor.withOpacity(0.3)),
                  ),
                  child: Text(toneLabel, style: TextStyle(color: toneColor, fontSize: 9, letterSpacing: 0.5)),
                ),
              ],
            ),
            if ((c['description'] ?? c['world_description']) != null) ...[
              const SizedBox(height: 6),
              Text(
                (c['description'] ?? c['world_description']) as String,
                style: const TextStyle(color: Color(0xFF8898B0), fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Play this world', style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 11)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Color(0xFF4A9EFF), size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

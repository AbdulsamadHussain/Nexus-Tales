import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../character/character_setup_screen.dart';
import '../game/game_screen.dart';
import 'create_campaign_screen.dart';

/// Landing screen shown after login.
/// Checks for existing canonical_state and routes accordingly.
class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final data = await Supabase.instance.client
          .from('canonical_state')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (data != null) {
        // Existing game — go straight in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0C10),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4A9EFF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'NEXUS-TALE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  letterSpacing: 6,
                  fontSize: 24,
                  color: Color(0xFFC9A84C),
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Where will your story begin?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF4A5A72), fontSize: 13),
              ),
              const SizedBox(height: 48),

              // ── Option A: Curated campaign ─────────────────────────
              _campaignOption(
                title: 'The Vault of the Plague Warden',
                subtitle: 'Curated campaign',
                description:
                    'A dark descent into a plague-ridden vault where an ancient warden '
                    'guards cursed knowledge. Pre-authored world, ready to play.',
                tone: 'Grimdark',
                accentColor: const Color(0xFFE05555),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CharacterSetupScreen()),
                ),
              ),
              const SizedBox(height: 16),

              // ── Option B: Custom campaign ──────────────────────────
              _campaignOption(
                title: 'Create your own world',
                subtitle: 'Custom campaign',
                description:
                    'Write your own setting, choose your narrator\'s voice, '
                    'and define the opening scene. The AI narrates within your world.',
                tone: 'Any tone',
                accentColor: const Color(0xFF4A9EFF),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateCampaignScreen()),
                ),
              ),

              const SizedBox(height: 32),
              TextButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campaignOption({
    required String title,
    required String subtitle,
    required String description,
    required String tone,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1219),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: accentColor.withOpacity(0.6), size: 14),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(color: accentColor, fontSize: 10, letterSpacing: 0.5),
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
                    tone,
                    style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(color: Color(0xFF8898B0), fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

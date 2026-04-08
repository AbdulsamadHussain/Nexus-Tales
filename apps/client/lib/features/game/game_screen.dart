import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _log = <Map<String, dynamic>>[];
  bool _busy = false;
  String? _lastRevisionId;
  Map<String, dynamic>? _canonicalState;

  @override
  void initState() {
    super.initState();
    _loadCanonicalState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCanonicalState() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final data = await Supabase.instance.client
        .from('canonical_state')
        .select('*')
        .eq('user_id', user.id)
        .single();
    setState(() => _canonicalState = data);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitAction() async {
    final action = _controller.text.trim();
    if (action.isEmpty || _busy) return;

    // Verify session is still valid
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _log.add({'type': 'system', 'text': 'Session expired. Please log in again.'});
      });
      return;
    }

    final user = Supabase.instance.client.auth.currentUser!;

    setState(() {
      _busy = true;
      _log.add({'type': 'player', 'text': action});
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // ── STEP 1: Simulation pipeline ───────────────────────────
      final response = await Supabase.instance.client.functions.invoke(
        'turn_orchestrator',
        body: {
          'user_id': user.id,
          'player_action': action,
          'previous_revision_id': _lastRevisionId,
          'content_settings': {
            'violence': true,
            'horror': true,
            'romance': false,
            'mature': false,
          },
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['status'] == 'REJECTED') {
        setState(() {
          _log.add({'type': 'system', 'text': '${data['player_message']}'});
        });
        _scrollToBottom();
        return;
      }

      _lastRevisionId = data['revision_id'] as String?;

      // Refresh canonical state
      _loadCanonicalState();

      // Show roll result
      if (data['roll'] != null) {
        final roll = data['roll'] as Map<String, dynamic>;
        setState(() {
          _log.add({
            'type': 'roll',
            'die': roll['die'],
            'modifier': roll['modifier'],
            'total': roll['total'],
            'dc': roll['dc'],
            'tier': data['success_tier'],
          });
        });
        _scrollToBottom();
      }

      // ── STEP 2: Narration via local Ollama ────────────────────
      final narration = await _callOllama(
        data['narration_context'] as String? ?? '',
        data['success_tier'] as String? ?? 'NO_ROLL',
      );

      setState(() {
        _log.add({'type': 'narrator', 'text': narration});
        _log.add({
          'type': 'system',
          'text':
              '${data['revision_id']} · ${data['success_tier']} · ${data['route_category']}',
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _log.add({'type': 'system', 'text': 'Error: $e'});
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _callOllama(String context, String tier) async {
    try {
      final uri = Uri.parse('http://localhost:11434/api/generate');
      final httpResponse = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'gemma4:e2b',
              'system':
                  'You are a dark fantasy game master narrator. '
                  'Respond ONLY with vivid narrative prose. '
                  'No thinking. No reasoning. No tags. No preamble. '
                  '2-4 sentences maximum. Second person present tense.',
              'prompt': context,
              'stream': false,
              'think': false,
              'options': {'temperature': 0.8, 'num_predict': 150},
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (httpResponse.statusCode == 200) {
        final body = jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final raw = body['response'] as String? ?? '';
        if (raw.contains('</think>')) {
          final cleaned = raw.substring(raw.lastIndexOf('</think>') + 8).trim();
          return cleaned.isEmpty ? _fallbackNarration(tier) : cleaned;
        }
        return raw.trim().isEmpty ? _fallbackNarration(tier) : raw.trim();
      }
      return _fallbackNarration(tier);
    } catch (_) {
      return _fallbackNarration(tier);
    }
  }

  String _fallbackNarration(String tier) {
    switch (tier) {
      case 'CRITICAL_SUCCESS':
        return 'You act with exceptional precision. The outcome exceeds all expectation.';
      case 'FULL_SUCCESS':
        return 'Your action succeeds. The moment resolves in your favour.';
      case 'PARTIAL_SUCCESS':
        return 'You partly succeed, but not without cost.';
      case 'FAILURE':
        return 'The attempt fails. The situation grows more dangerous.';
      case 'CRITICAL_FAILURE':
        return 'Everything goes wrong. The consequences are severe.';
      default:
        return 'The moment passes.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final charName = _canonicalState?['character_name'] ?? '...';
    final charClass = _canonicalState?['character_class'] ?? '';
    final hp = _canonicalState?['hp'] ?? 0;
    final hpMax = _canonicalState?['hp_max'] ?? 40;
    final mp = _canonicalState?['mp'] ?? 0;
    final mpMax = _canonicalState?['mp_max'] ?? 20;
    final stamina = _canonicalState?['stamina'] ?? 0;
    final staminaMax = _canonicalState?['stamina_max'] ?? 20;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1219),
        title: const Text(
          'NEXUS-TALE',
          style: TextStyle(
            letterSpacing: 4,
            color: Color(0xFFC9A84C),
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  charName,
                  style: const TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  charClass,
                  style: const TextStyle(
                    color: Color(0xFF4A5A72),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _statChip('HP', hp, hpMax, const Color(0xFFE05555)),
                const SizedBox(width: 6),
                _statChip('MP', mp, mpMax, const Color(0xFF4A9EFF)),
                const SizedBox(width: 6),
                _statChip('ST', stamina, staminaMax, const Color(0xFF4CAF82)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF4A5A72), size: 18),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _log.length,
              itemBuilder: (context, i) => _buildMessage(_log[i]),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _statChip(String label, int current, int max, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label $current/$max',
        style: TextStyle(color: color, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1219),
        border: Border(top: BorderSide(color: Color(0xFF1A2230))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_busy,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'What do you do?',
                hintStyle: TextStyle(color: Color(0xFF4A5A72)),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _submitAction(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _busy ? null : _submitAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D7DD2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Act'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    switch (msg['type']) {
      case 'player':
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, left: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF202C3E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              msg['text'] as String,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );

      case 'roll':
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1219),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF2D3A4A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'd20: ${msg['die']}',
                style: const TextStyle(
                  color: Color(0xFF4A9EFF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${msg['modifier']} = ${msg['total']} vs DC${msg['dc']}',
                style: const TextStyle(
                    color: Color(0xFF8898B0), fontSize: 13),
              ),
              const SizedBox(width: 8),
              _tierBadge(msg['tier'] as String),
            ],
          ),
        );

      case 'narrator':
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 12),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFF8A6D2E), width: 2),
            ),
          ),
          child: Text(
            msg['text'] as String,
            style: const TextStyle(
              color: Color(0xFFD4DCE8),
              fontStyle: FontStyle.italic,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        );

      default:
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2230),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            msg['text'] as String,
            style: const TextStyle(
              color: Color(0xFF8898B0),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        );
    }
  }

  Widget _tierBadge(String tier) {
    final colors = {
      'CRITICAL_SUCCESS': (const Color(0xFF1A2A0A), const Color(0xFF4CAF82)),
      'FULL_SUCCESS': (const Color(0xFF0A1A2A), const Color(0xFF4A9EFF)),
      'PARTIAL_SUCCESS': (const Color(0xFF2A1A0A), const Color(0xFFE09A40)),
      'FAILURE': (const Color(0xFF2A0A0A), const Color(0xFFE05555)),
      'CRITICAL_FAILURE': (const Color(0xFF3A0A0A), const Color(0xFFFF3333)),
    };
    final c = colors[tier] ??
        (const Color(0xFF1A2230), const Color(0xFF8898B0));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.$1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.$2.withOpacity(0.4)),
      ),
      child: Text(
        tier.replaceAll('_', ' '),
        style: TextStyle(color: c.$2, fontSize: 10, letterSpacing: 1),
      ),
    );
  }
}
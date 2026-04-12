import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'character_sheet_panel.dart';
import 'combat_panel.dart';
import 'saves_panel.dart';

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
  bool _showCharacterSheet = false;
  bool _showSavesPanel = false;
  List<Map<String, dynamic>> _npcsInScene = [];
  Map<String, dynamic> _npcStates = {};

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

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      setState(() {
        _log.add({
          'type': 'system',
          'text': 'Session expired. Please log in again.',
        });
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

      if (data['status'] == 'CLARIFICATION_REQUIRED') {
        final parsed = await _runParserAssist(action);
        if (parsed != null) {
          await _submitWithRoute(action, parsed['route']!, user.id);
        } else {
          setState(() {
            _log.add({
              'type': 'clarification',
              'text':
                  'What do you do? Describe your action — attack, search, move, speak, or use an item.',
            });
          });
          _scrollToBottom();
        }
        return;
      }

      _lastRevisionId = data['revision_id'] as String?;

      if (data['npcs_in_scene'] != null) {
        setState(() {
          _npcsInScene = (data['npcs_in_scene'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _npcStates = (data['npc_states'] as Map<String, dynamic>?) ?? {};
        });
      }

      _loadCanonicalState();

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

      final narration = await _callOllama(
        data['narration_context'] as String? ?? '',
        data['success_tier'] as String? ?? 'NO_ROLL',
      );
      _scrollToBottom();
      _triggerSummaryWorker(data, action);

      setState(() {
        _log.add({'type': 'narrator', 'text': narration});
        _log.add({
          'type': 'system',
          'text':
              '${data['revision_id']} · ${data['success_tier']} · ${data['route_category']}',
        });
      });
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
        debugPrint('=== NARRATION RAW ===');
        debugPrint(raw);
        debugPrint('=== END ===');
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
            icon: Icon(
              Icons.person,
              color: _showCharacterSheet
                  ? const Color(0xFF4A9EFF)
                  : const Color(0xFF4A5A72),
              size: 18,
            ),
            onPressed: () =>
                setState(() => _showCharacterSheet = !_showCharacterSheet),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF4A5A72), size: 18),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.save_outlined,
              color: _showSavesPanel
                  ? const Color(0xFF4CAF82)
                  : const Color(0xFF4A5A72),
              size: 18,
            ),
            onPressed: () => setState(() => _showSavesPanel = !_showSavesPanel),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _log.length,
                    itemBuilder: (context, i) => _buildMessage(_log[i]),
                  ),
                ),
                if (_npcsInScene.any(
                  (n) =>
                      n['is_hostile'] == true &&
                      (_npcStates[n['id']]?['is_dead'] != true),
                ))
                  CombatPanel(npcsInScene: _npcsInScene, npcStates: _npcStates),
                _buildInputBar(),
              ],
            ),
          ),
          if (_showSavesPanel)
            SavesPanel(
              onClose: () => setState(() => _showSavesPanel = false),
              onLoaded: () async {
                await _loadCanonicalState();
                setState(() {
                  _showSavesPanel = false;
                  _npcsInScene.clear();
                  _npcStates.clear();
                  _log.add({
                    'type': 'save_divider',
                    'text': 'Game loaded from save.',
                  });
                });
              },
            ),
          if (_showCharacterSheet && _canonicalState != null)
            CharacterSheetPanel(
              canonicalState: _canonicalState!,
              onClose: () => setState(() => _showCharacterSheet = false),
            ),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _submitAction(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _busy ? null : _submitAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D7DD2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                style: const TextStyle(color: Color(0xFF8898B0), fontSize: 13),
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

      case 'clarification':
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2230),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF8A6D2E)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: Color(0xFFC9A84C),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  msg['text'] as String,
                  style: const TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'save_divider':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Expanded(
                child: Divider(color: Color(0xFF2D3A4A), thickness: 1),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2230),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4CAF82).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.restore, color: Color(0xFF4CAF82), size: 12),
                    SizedBox(width: 5),
                    Text(
                      'SAVE LOADED',
                      style: TextStyle(
                        color: Color(0xFF4CAF82),
                        fontSize: 9,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Divider(color: Color(0xFF2D3A4A), thickness: 1),
              ),
            ],
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
    final c =
        colors[tier] ?? (const Color(0xFF1A2230), const Color(0xFF8898B0));
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

  Future<Map<String, String>?> _runParserAssist(String input) async {
    try {
      final prompt =
          '''You are a game action classifier for a dark fantasy RPG.
Classify the player input and respond with ONLY a JSON object. No explanation.

Player input: "$input"

You MUST respond with exactly this structure:
{"route": "NO_ROLL_DETERMINISTIC", "action_type": "SPEAK"}

The "route" field MUST be one of these exact strings only:
- "NO_ROLL_DETERMINISTIC" (for speaking, examining, moving, using items)
- "ROLL_REQUIRED" (for attacking, sneaking, lockpicking, skill checks)
- "SAFE_REJECT" (for harmful real-world requests)

The "action_type" field MUST be one of:
- "SPEAK" "EXAMINE" "MOVE" "USE_ITEM" "ATTACK" "STEALTH" "SKILL_CHECK" "OTHER"

Examples:
Input: "I say hello to the guard" → {"route": "NO_ROLL_DETERMINISTIC", "action_type": "SPEAK"}
Input: "my blade finds the gap" → {"route": "ROLL_REQUIRED", "action_type": "ATTACK"}
Input: "I can carry the truth is what I say to the warden" → {"route": "NO_ROLL_DETERMINISTIC", "action_type": "SPEAK"}
Input: "the cabinet I need what is inside" → {"route": "ROLL_REQUIRED", "action_type": "SKILL_CHECK"}''';

      final uri = Uri.parse('http://localhost:11434/api/generate');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'gemma4:e2b',
              'prompt': prompt,
              'stream': false,
              'think': false,
              'options': {'temperature': 0.1, 'num_predict': 60},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = body['response'] as String? ?? '';

      debugPrint('=== PARSER RAW ===');
      debugPrint(raw);
      debugPrint('=== END ===');

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
      if (jsonMatch == null) return null;

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      final validRoutes = [
        'ROLL_REQUIRED',
        'NO_ROLL_DETERMINISTIC',
        'SAFE_REJECT',
      ];
      final route = parsed['route'] as String?;
      if (route == null || !validRoutes.contains(route)) return null;
      if (route == 'SAFE_REJECT') return null;

      debugPrint('=== PARSER ASSIST ===');
      debugPrint(
        'Input: $input → route: $route, action: ${parsed['action_type']}',
      );
      debugPrint('=== END ===');

      return {
        'route': route,
        'action_type': parsed['action_type'] as String? ?? 'OTHER',
      };
    } catch (e) {
      debugPrint('Parser assist error: $e');
      return null;
    }
  }

  Future<void> _submitWithRoute(
    String action,
    String resolvedRoute,
    String userId,
  ) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'turn_orchestrator',
        body: {
          'user_id': userId,
          'player_action': action,
          'previous_revision_id': _lastRevisionId,
          'resolved_route': resolvedRoute,
          'content_settings': {
            'violence': true,
            'horror': true,
            'romance': false,
            'mature': false,
          },
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] == 'CLARIFICATION_REQUIRED') {
        setState(() {
          _log.add({
            'type': 'clarification',
            'text': 'What do you do? Describe your action clearly.',
          });
        });
        _scrollToBottom();
        return;
      }

      _lastRevisionId = data['revision_id'] as String?;

      if (data['npcs_in_scene'] != null) {
        setState(() {
          _npcsInScene = (data['npcs_in_scene'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _npcStates = (data['npc_states'] as Map<String, dynamic>?) ?? {};
        });
      }

      _loadCanonicalState();

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

      final narration = await _callOllama(
        data['narration_context'] as String? ?? '',
        data['success_tier'] as String? ?? 'NO_ROLL',
      );

      setState(() {
        _log.add({'type': 'narrator', 'text': narration});
        _log.add({
          'type': 'system',
          'text':
              '${data['revision_id']} · ${data['success_tier']} · ${data['route_category']} · parser_assisted',
        });
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _log.add({'type': 'system', 'text': 'Error: $e'});
      });
      _scrollToBottom();
    }
  }

  Future<void> _triggerSummaryWorker(
    Map<String, dynamic> data,
    String action,
  ) async {
    debugPrint(
      'Summary check: summary_job_queued = ${data['summary_job_queued']}',
    );
    if (data['summary_job_queued'] != true) return;

    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.functions.invoke(
        'summary_worker',
        body: {
          'user_id': user.id,
          'revision_id': data['revision_id'],
          'trigger_type': 'hard',
          'events': data['events'],
          'narration_context': data['narration_context'] ?? '',
          'ollama_url': 'http://localhost:11434',
        },
      );
      debugPrint(
        'Summary worker triggered for revision ${data['revision_id']}',
      );
    } catch (e) {
      debugPrint('Summary worker failed (non-blocking): $e');
    }
  }
}

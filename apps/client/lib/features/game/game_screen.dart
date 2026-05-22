import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../character/character_select_screen.dart';
import 'character_sheet_panel.dart';
import 'combat_panel.dart';
import 'narration_fallback.dart';
import 'saves_panel.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String characterId;
  const GameScreen({super.key, required this.characterId});

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
  bool _hintsVisible = true;
  List<Map<String, dynamic>> _npcsInScene = [];
  Map<String, dynamic> _npcStates = {};

  String? _lastRevisionId;
  Map<String, dynamic>? _canonicalState;
  Map<String, dynamic>? _userPreferences;
  Map<String, dynamic>? _campaign;

  @override
  void initState() {
    super.initState();
    _loadCanonicalState();
    _loadUserPreferences();
    _loadCampaign();
    _loadHistory();
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
        .eq('character_id', widget.characterId)
        .single();
    if (mounted) {
      setState(() => _canonicalState = data);
      if (_log.isEmpty) _checkTimePassed();
    }
    // Trigger opening narration once both state and campaign are ready
    _maybeGenerateOpening();
    // Restore NPC states after loading canonical state
    await _loadNpcStates();
  }

  void _checkTimePassed() {
    if (_canonicalState == null) return;
    final updatedAt = _canonicalState!['updated_at'] as String?;
    if (updatedAt == null) return;
    final lastPlayed = DateTime.tryParse(updatedAt);
    if (lastPlayed == null) return;
    final hoursPassed = DateTime.now().difference(lastPlayed).inHours;
    if (hoursPassed >= 8) {
      final timeStr = hoursPassed >= 48
          ? '${(hoursPassed / 24).floor()} days'
          : '$hoursPassed hours';
      setState(() {
        _log.insert(0, {
          'type': 'system',
          'text': '— $timeStr have passed since your last session —',
        });
      });
    }
  }

  Future<void> _loadNpcStates() async {
    if (_canonicalState == null) return;
    final user = Supabase.instance.client.auth.currentUser!;
    final campaignId = _canonicalState!['campaign_id'] as String?;
    final location = _canonicalState!['current_location'] as String?;
    if (campaignId == null || location == null) return;

    try {
      // Load player_campaign_state for npc_states
      final pcs = await Supabase.instance.client
          .from('player_campaign_state')
          .select('npc_states')
          .eq('character_id', widget.characterId)
          .eq('campaign_id', campaignId)
          .maybeSingle();

      final npcStates = (pcs?['npc_states'] as Map?)?.cast<String, dynamic>() ?? {};

      // Load NPCs in current scene
      final sceneNpcRows = await Supabase.instance.client
          .from('scene_npcs')
          .select('npc_id, npcs(id, name, archetype, is_hostile, hp, faction, attack_damage)')
          .eq('scene_id', location);

      final npcsInScene = <Map<String, dynamic>>[];
      for (final row in sceneNpcRows) {
        final npc = row['npcs'];
        if (npc != null) npcsInScene.add(Map<String, dynamic>.from(npc as Map));
      }

      if (mounted) {
        setState(() {
          _npcStates = npcStates;
          _npcsInScene = npcsInScene;
        });
      }
    } catch (e) {
      debugPrint('NPC state load failed: $e');
    }
  }

  Future<void> _loadCampaign() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final state = await Supabase.instance.client
        .from('canonical_state')
        .select('campaign_id')
        .eq('user_id', user.id)
        .eq('character_id', widget.characterId)
        .maybeSingle();
    if (state == null) return;
    final campaignId = state['campaign_id'] as String?;
    if (campaignId == null) return;
    final data = await Supabase.instance.client
        .from('campaigns')
        .select('title, narrator_tone, world_description, is_custom')
        .eq('id', campaignId)
        .maybeSingle();
    if (data != null && mounted) setState(() => _campaign = data);
    _maybeGenerateOpening();
  }

  bool _openingTriggered = false;

  Future<void> _loadHistory() async {
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final revisions = await Supabase.instance.client
          .from('revisions')
          .select('revision_id, player_action, success_tier, route_category, created_at')
          .eq('user_id', user.id)
          .eq('character_id', widget.characterId)
          .order('created_at', ascending: false)
          .limit(20);

      final ordered = List.from(revisions.reversed);
      final history = <Map<String, dynamic>>[];
      for (final rev in ordered) {
        final action = rev['player_action'] as String? ?? '';
        if (action.isNotEmpty) {
          history.add({'type': 'player', 'text': action});
        }
        history.add({
          'type': 'system',
          'text': '${rev['revision_id']} · ${rev['success_tier']} · ${rev['route_category']}',
        });
      }
      if (mounted && history.isNotEmpty) {
        setState(() => _log.addAll(history));
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('History load failed: $e');
    }
  }

  Future<void> _maybeGenerateOpening() async {
    // Wait until both canonical state and campaign are loaded, and only fire once
    if (_openingTriggered) return;
    if (_canonicalState == null) return;
    _openingTriggered = true;

    // Only generate opening for brand new characters (no turns taken yet)
    final turnCount = _canonicalState!['turn_count'] as int? ?? 0;
    if (turnCount > 0) return; // returning player — skip

    // Load the starting scene description
    final location = _canonicalState!['current_location'] as String?;
    Map<String, dynamic>? scene;
    if (location != null) {
      scene = await Supabase.instance.client
          .from('scenes')
          .select('title, description, atmosphere')
          .eq('id', location)
          .maybeSingle();
    }

    final sceneTitle = scene?['title'] as String? ?? 'an unknown place';
    final sceneDesc = scene?['description'] as String? ?? '';
    final sceneAtmo = scene?['atmosphere'] as String? ?? '';

    final context = [
      'Scene: $sceneTitle',
      if (sceneDesc.isNotEmpty) sceneDesc,
      if (sceneAtmo.isNotEmpty) 'Atmosphere: $sceneAtmo',
      'The player has just arrived. Open the scene.',
    ].join('\n');

    if (mounted) setState(() => _busy = true);

    await _streamNarration(context, 'NO_ROLL');
    if (mounted) setState(() => _busy = false);
    _scrollToBottom();
  }

  Future<void> _loadUserPreferences() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final data = await Supabase.instance.client
        .from('user_preferences')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();
    if (data != null) {
      setState(() => _userPreferences = data);
    }
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
    setState(() => _hintsVisible = false);
    final action = _controller.text.trim();
    if (action.isEmpty || _busy) return;

    final hp = _canonicalState?['hp'] as int? ?? 1;
    if (hp <= 0) return; // dead — block input

    // Intercept shop/merchant commands
    final lowerAction = action.toLowerCase();
    if (RegExp(r'\b(shop|buy|purchase|merchant|store|market|wares)\b').hasMatch(lowerAction)) {
      _controller.clear();
      setState(() => _busy = false);
      _showShopModal();
      return;
    }

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
          'character_id': widget.characterId,
          'player_action': action,
          'previous_revision_id': _lastRevisionId,
          'content_settings': _getContentSettings(),
        },
      );

      final data = response.data as Map<String, dynamic>;

      // Handle gateway REJECT
      if (data['status'] == 'REJECTED') {
        setState(() {
          _log.add({
            'type': 'system',
            'text':
                data['player_message'] as String? ??
                'That action is not allowed.',
          });
        });
        _scrollToBottom();
        return;
      }

      // §6.3 — No-op after 3 consecutive ambiguous turns
      if (data['status'] == 'NO_OP') {
        setState(() {
          _log.add({
            'type': 'system',
            'text':
                data['player_message'] as String? ??
                'Your intent remains unclear. Try a different approach.',
          });
        });
        _scrollToBottom();
        return;
      }

      // Clarification — try parser assist, but only resubmit if it resolved
      // to a real actionable route. CLARIFICATION_REQUIRED from the parser
      // means it also couldn't resolve — just show the clarification bubble.
      // The orchestrator already incremented the ambiguity counter this turn.
      if (data['status'] == 'CLARIFICATION_REQUIRED') {
        final parsed = await _runParserAssist(action);
        if (parsed != null) {
          // Parser resolved to a real route — resubmit with it
          await _submitWithRoute(action, parsed['route']!, parsed['action_type']!, parsed['candidate_skill'], user.id);
        } else {
          // Parser couldn't resolve — show clarification bubble
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

      final rawConstraints = data['narration_constraints'];
      final constraints = rawConstraints is List
          ? rawConstraints.map((e) => e.toString()).toList()
          : <String>[];

      await _streamNarration(
        data['narration_context'] as String? ?? '',
        data['success_tier'] as String? ?? 'NO_ROLL',
        constraints: constraints,
        simResult: data,
      );
      _scrollToBottom();
      _triggerSummaryWorker(data, action);

      setState(() {
        _log.add({
          'type': 'system',
          'text':
              '${data['revision_id']} · ${data['success_tier']} · ${data['route_category']}',
        });
      });

      // Check for LEVEL_UP events
      final events = data['events'] as List<dynamic>? ?? [];
      for (final event in events) {
        final eventStr = event.toString();
        if (eventStr.startsWith('LEVEL_UP:')) {
          final newLevel = eventStr.split(':').last;
          setState(() {
            _log.add({'type': 'level_up', 'text': 'Level $newLevel'});
          });
          _showLevelUpDialog(newLevel);
        }
      }

      // Silent autosave when the simulation flags it
      if (data['autosave_candidate'] == true) {
        _triggerAutosave();
      }
    } catch (e) {
      setState(() {
        _log.add({'type': 'system', 'text': 'Error: $e'});
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _buildSystemPrompt(String constraintText) {
    final tone = _campaign?['narrator_tone'] as String? ?? 'grimdark';
    final worldDesc = _campaign?['world_description'] as String? ?? '';
    final campaignTitle = _campaign?['title'] as String? ?? '';
    final isCustom = _campaign?['is_custom'] as bool? ?? false;

    // Tone: writing style rules the LLM must follow
    final (toneLabel, toneRules) = switch (tone) {
      'epic' => (
        'Epic Fantasy',
        'Write with grandeur and weight. Every action carries consequence. '
        'Use elevated language — not flowery, but purposeful. '
        'Reference fate, legacy, and the scale of the world. No irony.',
      ),
      'horror' => (
        'Cosmic Horror',
        'Build dread through implication, not description. '
        'What is NOT seen is scarier than what is. '
        'The world is indifferent to the player. Sanity is fragile. '
        'Never resolve tension fully. Leave the reader unsettled.',
      ),
      'dark_comedy' => (
        'Dark Comedy',
        'Sardonic, dry, and bleak. The absurdity of suffering is acknowledged but never celebrated. '
        'A wry observation undercuts every moment of genuine horror. '
        'Deadpan delivery. The world is awful and everyone knows it.',
      ),
      'gritty' => (
        'Gritty Realism',
        'Low fantasy. No magic solves problems. Bodies hurt, resources run out. '
        'Every NPC has their own agenda. Write with restraint — no heroic flourishes. '
        'Consequences are permanent. The world does not care about the player.',
      ),
      'mythic' => (
        'Mythic',
        'Legendary scope. Gods intervene. Ancient powers stir. '
        'Write as if describing events that will be remembered for centuries. '
        'The player\'s choices echo through time. Use mythic imagery.',
      ),
      _ => (
        'Grimdark',
        'Brutal and morally ambiguous. No safe heroes. Violence has weight and cost. '
        'Villains have reasons. Heroes make terrible choices. '
        'Write with grim poetry — beautiful sentences about ugly truths. '
        'Never offer false hope.',
      ),
    };

    // Character context
    final charName = _canonicalState?['character_name'] as String? ?? 'the player';
    final charClass = _canonicalState?['character_class'] as String? ?? '';
    final charOrigin = _canonicalState?['origin'] as String? ?? '';
    final charBackstory = _canonicalState?['backstory'] as String? ?? '';

    final charLines = <String>[];
    if (charClass.isNotEmpty) charLines.add('Class: $charClass');
    if (charOrigin.isNotEmpty) charLines.add('Origin: $charOrigin');
    if (charBackstory.isNotEmpty) charLines.add('Background: $charBackstory');

    // World context
    final worldLines = <String>[];
    if (isCustom && campaignTitle.isNotEmpty) worldLines.add('World: $campaignTitle');
    if (worldDesc.isNotEmpty) worldLines.add(worldDesc);

    final buf = StringBuffer();
    buf.writeln('You are the narrator of a $toneLabel tabletop RPG.');
    buf.writeln();
    buf.writeln('WRITING RULES (follow strictly):');
    buf.writeln('- Respond ONLY with vivid narrative prose. No lists, no headers, no meta-commentary.');
    buf.writeln('- 2–4 sentences maximum. Be dense and deliberate, not verbose.');
    buf.writeln('- Second person present tense ("You step into...", "The guard eyes you...").');
    buf.writeln('- Never repeat what the player just said. Advance the scene.');
    buf.writeln('- Never speak as the player or make decisions for them.');
    buf.writeln('- No XML tags, no thinking out loud, no preamble.');
    buf.writeln();
    buf.writeln('TONE — $toneLabel:');
    buf.writeln(toneRules);

    if (worldLines.isNotEmpty) {
      buf.writeln();
      buf.writeln('WORLD:');
      for (final line in worldLines) buf.writeln(line);
    }

    if (charLines.isNotEmpty) {
      buf.writeln();
      buf.writeln('THE PLAYER CHARACTER — $charName:');
      for (final line in charLines) buf.writeln(line);
      buf.writeln('Reference their background only when it\'s naturally relevant. Never narrate their inner thoughts.');
    }

    if (constraintText.isNotEmpty) {
      buf.writeln();
      buf.writeln('CONTENT CONSTRAINTS:$constraintText');
    }

    return buf.toString().trim();
  }

  Future<String> _callOllama(
    String context,
    String tier, {
    List<String> constraints = const [],
    Map<String, dynamic> simResult = const {},
  }) async {
    try {
      final constraintText = constraints.isNotEmpty
          ? ' Content restrictions: ${constraints.join(", ")}. Obey these strictly.'
          : '';

      final systemPrompt = _buildSystemPrompt(constraintText);

      final uri = Uri.parse('http://localhost:11434/api/generate');
      final httpResponse = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'gemma4:e2b',
              'system': systemPrompt,

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
          return cleaned.isEmpty ? _fallbackNarration(tier, simResult) : cleaned;
        }
        return raw.trim().isEmpty ? _fallbackNarration(tier, simResult) : raw.trim();
      }
      return _fallbackNarration(tier, simResult);
    } catch (_) {
      return _fallbackNarration(tier, simResult);
    }
  }

  // Delegates to the pure extracted function in narration_fallback.dart
  // so the logic can be unit tested without Flutter widget dependencies.
  String _fallbackNarration(String tier, Map<String, dynamic> data) =>
      buildFallbackNarration(tier, data);

  Future<void> _streamNarration(
    String context,
    String tier, {
    List<String> constraints = const [],
    Map<String, dynamic> simResult = const {},
  }) async {
    final constraintText = constraints.isNotEmpty
        ? ' Content restrictions: ${constraints.join(", ")}. Obey these strictly.'
        : '';
    final systemPrompt = _buildSystemPrompt(constraintText);

    // Add placeholder entry immediately so UI shows something
    if (!mounted) return;
    setState(() => _log.add({'type': 'narrator', 'text': ''}));
    final entryIndex = _log.length - 1;

    final buffer = StringBuffer();

    try {
      final client = http.Client();
      final request = http.Request('POST', Uri.parse('http://localhost:11434/api/generate'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': 'gemma4:e2b',
        'system': systemPrompt,
        'prompt': context,
        'stream': true,
        'think': false,
        'options': {'temperature': 0.8, 'num_predict': 150},
      });

      final streamed = await client.send(request).timeout(const Duration(seconds: 30));

      await for (final line in streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final token = json['response'] as String? ?? '';
          buffer.write(token);

          String display = buffer.toString();
          if (display.contains('</think>')) {
            display = display.substring(display.lastIndexOf('</think>') + 8).trim();
          }

          if (mounted) {
            setState(() => _log[entryIndex] = {
              'type': 'narrator',
              'text': display.isEmpty ? '...' : display,
            });
            _scrollToBottom();
          }

          if (json['done'] == true) break;
        } catch (_) {}
      }
      client.close();
    } catch (_) {
      // Fallback on error
    }

    // If nothing was streamed, use fallback
    if (buffer.isEmpty && mounted) {
      setState(() => _log[entryIndex] = {
        'type': 'narrator',
        'text': _fallbackNarration(tier, simResult),
      });
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF4A5A72), size: 18),
            color: const Color(0xFF0F1219),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF1A2230)),
            ),
            onSelected: (value) async {
              if (value == 'switch') {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const CharacterSelectScreen(),
                    ),
                  );
                }
              } else if (value == 'logout') {
                await Supabase.instance.client.auth.signOut();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'switch',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Color(0xFF4A9EFF), size: 16),
                    SizedBox(width: 10),
                    Text('Switch character', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFF4A5A72), size: 16),
                    SizedBox(width: 10),
                    Text('Sign out', style: TextStyle(color: Color(0xFF4A5A72), fontSize: 13)),
                  ],
                ),
              ),
            ],
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
                    itemCount: _log.length + (_busy ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_busy && i == _log.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessage(_log[i]);
                    },
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
              characterId: widget.characterId,
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
              contentSettings:
                  _userPreferences?['content_settings']
                      as Map<String, dynamic>? ??
                  {},
              onClose: () => setState(() => _showCharacterSheet = false),
              onSettingChanged: () async {
                await _loadUserPreferences();
                await _loadCanonicalState();
              },
              onUseItem: (action) {
                setState(() => _showCharacterSheet = false);
                _controller.text = action;
                _submitAction();
              },
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
    final hp = _canonicalState?['hp'] as int? ?? 1;
    if (hp <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1A0A0A),
          border: Border(top: BorderSide(color: Color(0xFF3A1A1A))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'YOU HAVE FALLEN',
              style: TextStyle(color: Color(0xFFE05555), fontSize: 13, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showSavesPanel = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2230),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Load a save', style: TextStyle(color: Color(0xFF4A9EFF), fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestPin(),
        if (_hintsVisible && (_canonicalState?['turn_count'] as int? ?? 0) == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                'I look around',
                'I examine the area',
                'I search for anything useful',
                'I call out into the darkness',
              ].map((hint) => GestureDetector(
                onTap: () {
                  _controller.text = hint;
                  setState(() => _hintsVisible = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2230),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D3A4A)),
                  ),
                  child: Text(hint, style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 11)),
                ),
              )).toList(),
            ),
          ),
        Container(
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
        ),
      ],
    );
  }

  Widget _buildQuestPin() {
    final questState = _canonicalState?['quest_state'] as Map? ?? {};
    // Find first active quest
    String? activeQuestName;
    String? activeQuestObj;
    for (final entry in questState.entries) {
      final q = entry.value;
      if (q is Map) {
        final status = q['status'] as String? ?? '';
        if (status == 'active' || status == 'in_progress') {
          activeQuestName = _formatQuestId(entry.key as String);
          activeQuestObj = q['objective'] as String? ?? q['description'] as String? ?? '';
          break;
        }
      }
    }
    if (activeQuestName == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1A2E),
        border: Border(top: BorderSide(color: Color(0xFF1A2D4A))),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes, color: Color(0xFF4A9EFF), size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$activeQuestName  ',
                  style: const TextStyle(color: Color(0xFF4A9EFF), fontSize: 10, letterSpacing: 0.5),
                ),
                TextSpan(
                  text: activeQuestObj,
                  style: const TextStyle(color: Color(0xFF8898B0), fontSize: 10),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatQuestId(String id) {
    return id.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: const BoxDecoration(
              color: Color(0xFF1A2230),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories, size: 14, color: Color(0xFFC9A84C)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1219),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1A2230)),
            ),
            child: const _PulsingDots(),
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

      case 'level_up':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.5)),
            borderRadius: BorderRadius.circular(6),
            color: const Color(0xFF1A1500),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFC9A84C), size: 14),
              const SizedBox(width: 8),
              Text(
                '✦  LEVEL UP — ${msg['text']}  ✦',
                style: const TextStyle(
                  color: Color(0xFFC9A84C),
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.auto_awesome, color: Color(0xFFC9A84C), size: 14),
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

  /// Parser assist — returns a resolved route only if Gemma can classify
  /// the input as a real actionable route. Returns null if unclear.
  /// CLARIFICATION_REQUIRED from the parser is treated as null —
  /// the orchestrator already counted this turn's ambiguity.
  Future<Map<String, String?>?> _runParserAssist(String input) async {
    try {
      final prompt =
          '''You are a game action classifier for a dark fantasy RPG.
Classify the player input and respond with ONLY a JSON object. No explanation.

Player input: "$input"

You MUST respond with exactly this structure:
{"route": "NO_ROLL_DETERMINISTIC", "action_type": "SPEAK"}

If the route is "ROLL_REQUIRED", you MUST also include a "candidate_skill" field (e.g., "melee", "stealth", "persuasion", "perception", "lockpick", "strength").

The "route" field MUST be one of these exact strings only:
- "NO_ROLL_DETERMINISTIC" (for speaking, examining, moving, using items)
- "ROLL_REQUIRED" (for attacking, sneaking, lockpicking, skill checks)
- "CLARIFICATION_REQUIRED" (for vague, unclear, or nonsensical inputs)
- "SAFE_REJECT" (for harmful real-world requests)

The "action_type" field MUST be one of:
- "SPEAK" "EXAMINE" "MOVE" "USE_ITEM" "ATTACK" "STEALTH" "SKILL_CHECK" "OTHER"

Examples:
Input: "I say hello to the guard" → {"route": "NO_ROLL_DETERMINISTIC", "action_type": "SPEAK"}
Input: "my blade finds the gap" → {"route": "ROLL_REQUIRED", "action_type": "ATTACK"}
Input: "maybe" → {"route": "CLARIFICATION_REQUIRED", "action_type": "OTHER"}
Input: "hmm" → {"route": "CLARIFICATION_REQUIRED", "action_type": "OTHER"}
Input: "what if" → {"route": "CLARIFICATION_REQUIRED", "action_type": "OTHER"}
Input: "the cabinet I need what is inside" → {"route": "ROLL_REQUIRED", "action_type": "SKILL_CHECK", "candidate_skill": "lockpick"}''';

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

      final route = parsed['route'] as String?;

      // Only forward real actionable routes — never forward CLARIFICATION_REQUIRED
      // or SAFE_REJECT back to the orchestrator. The counter already incremented.
      const actionableRoutes = ['ROLL_REQUIRED', 'NO_ROLL_DETERMINISTIC'];
      if (route == null || !actionableRoutes.contains(route)) return null;

      debugPrint('=== PARSER ASSIST ===');
      debugPrint('route: ${parsed['route']}, action_type: ${parsed['action_type']}, skill: ${parsed['candidate_skill']}');
      debugPrint('=== END ===');
      
      debugPrint('=== PARSER ASSIST ===');
      debugPrint(
        'Input: $input → route: $route, action: ${parsed['action_type']}',
      );
      debugPrint('=== END ===');

      return {
        'route': route,
        'action_type': parsed['action_type'] as String? ?? 'OTHER',
        'candidate_skill': parsed['candidate_skill'] as String?,
      };
    } catch (e) {
      debugPrint('Parser assist error: $e');
      return null;
    }
  }

  Future<void> _submitWithRoute(
    String action,
    String resolvedRoute,
    String resolvedActionType,
    String? candidateSkill,
    String userId,
  ) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'turn_orchestrator',
        body: {
          'user_id': userId,
          'character_id': widget.characterId,
          'player_action': action,
          'previous_revision_id': _lastRevisionId,
          'resolved_route': resolvedRoute,
          'resolved_action_type': resolvedActionType,
          if (candidateSkill != null) 'candidate_skill': candidateSkill,
          'content_settings': _getContentSettings(),
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['status'] == 'REJECTED') {
        setState(() {
          _log.add({
            'type': 'system',
            'text':
                data['player_message'] as String? ??
                'That action is not allowed.',
          });
        });
        _scrollToBottom();
        return;
      }

      if (data['status'] == 'NO_OP') {
        setState(() {
          _log.add({
            'type': 'system',
            'text':
                data['player_message'] as String? ??
                'Your intent remains unclear. Try a different approach.',
          });
        });
        _scrollToBottom();
        return;
      }

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

      final rawConstraints = data['narration_constraints'];
      final constraints = rawConstraints is List
          ? rawConstraints.map((e) => e.toString()).toList()
          : <String>[];

      await _streamNarration(
        data['narration_context'] as String? ?? '',
        data['success_tier'] as String? ?? 'NO_ROLL',
        constraints: constraints,
        simResult: data,
      );

      setState(() {
        _log.add({
          'type': 'system',
          'text':
              '${data['revision_id']} · ${data['success_tier']} · ${data['route_category']} · parser_assisted',
        });
      });

      // Check for LEVEL_UP events
      final routeEvents = data['events'] as List<dynamic>? ?? [];
      for (final event in routeEvents) {
        final eventStr = event.toString();
        if (eventStr.startsWith('LEVEL_UP:')) {
          final newLevel = eventStr.split(':').last;
          setState(() {
            _log.add({'type': 'level_up', 'text': 'Level $newLevel'});
          });
          _showLevelUpDialog(newLevel);
        }
      }

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
          'character_id': widget.characterId,
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

  Future<void> _triggerAutosave() async {
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final now = DateTime.now();
      await Supabase.instance.client.functions.invoke(
        'save_manager',
        body: {
          'action': 'SAVE',
          'user_id': user.id,
          'character_id': widget.characterId,
          'save_name':
              'Autosave ${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        },
      );
      debugPrint('Autosave triggered');
    } catch (e) {
      debugPrint('Autosave failed (non-blocking): $e');
    }
  }

  Map<String, dynamic> _getContentSettings() {
    final raw = _userPreferences?['content_settings'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {
      'violence': true,
      'graphic': false,
      'horror': true,
      'romance': true,
      'mature': false,
    };
  }

  // ── LEVEL-UP SKILL CHOICE ────────────────────────────────────────

  static const Map<String, List<Map<String, dynamic>>> _classskills = {
    'Rogue': [
      {'id': 'shadow_step', 'name': 'Shadow Step', 'desc': '+2 to stealth and evasion rolls.'},
      {'id': 'pick_lock', 'name': 'Pick Lock', 'desc': '+3 to skill checks involving locks, traps, and secrets.'},
      {'id': 'vanish', 'name': 'Vanish', 'desc': 'Escape combat without a counter-attack once per scene.'},
      {'id': 'blade_dance', 'name': 'Blade Dance', 'desc': 'Attack twice in one turn. Second hit at half damage.'},
      {'id': 'poison_craft', 'name': 'Poison Craft', 'desc': 'Attacks can inflict Poison status (3 HP per turn).'},
    ],
    'War Mage': [
      {'id': 'arcane_burst', 'name': 'Arcane Burst', 'desc': '+3 to attack rolls, costs 8 MP.'},
      {'id': 'mana_shield', 'name': 'Mana Shield', 'desc': 'Absorb the next hit with MP instead of HP.'},
      {'id': 'time_echo', 'name': 'Time Echo', 'desc': 'Reroll one failed check per scene.'},
      {'id': 'chain_lightning', 'name': 'Chain Lightning', 'desc': 'Hit up to 3 enemies in one turn. 10 MP cost.'},
      {'id': 'spell_haste', 'name': 'Spell Haste', 'desc': 'Reduce MP cost of all spells by 2.'},
    ],
    'Warden': [
      {'id': 'iron_guard', 'name': 'Iron Guard', 'desc': '+10 max HP permanently.'},
      {'id': 'shield_bash', 'name': 'Shield Bash', 'desc': 'Stagger enemy, skipping their counter-attack.'},
      {'id': 'rally', 'name': 'Rally', 'desc': 'Restore 15 stamina as a free action once per scene.'},
      {'id': 'bulwark', 'name': 'Bulwark', 'desc': 'Reduce all incoming damage by 2.'},
      {'id': 'taunt', 'name': 'Taunt', 'desc': 'Force all hostile NPCs to target you for 2 turns.'},
    ],
    'Plague Doctor': [
      {'id': 'toxin_expertise', 'name': 'Toxin Expertise', 'desc': 'All potions and salves heal 5 extra HP.'},
      {'id': 'mercy_stroke', 'name': 'Mercy Stroke', 'desc': '+2 to attacks against injured (< 50% HP) enemies.'},
      {'id': 'field_medicine', 'name': 'Field Medicine', 'desc': 'Stabilise allies at 0 HP; they survive at 1 HP.'},
      {'id': 'plague_cloud', 'name': 'Plague Cloud', 'desc': 'Infect all enemies in scene with Poison status.'},
      {'id': 'antidote', 'name': 'Antidote', 'desc': 'Cure any status effect on yourself as a free action.'},
    ],
    'Hex Blade': [
      {'id': 'curse', 'name': 'Curse', 'desc': 'Enemy takes -2 to all rolls for 3 turns. 6 MP cost.'},
      {'id': 'dark_pact', 'name': 'Dark Pact', 'desc': 'Trade 10 HP for 15 MP once per scene.'},
      {'id': 'soul_leech', 'name': 'Soul Leech', 'desc': 'Restore 5 HP on every NPC kill.'},
      {'id': 'hex_bolt', 'name': 'Hex Bolt', 'desc': 'Ranged hex attack; no counter-attack possible.'},
      {'id': 'eldritch_armor', 'name': 'Eldritch Armor', 'desc': 'Gain 3 temporary HP per turn in combat.'},
    ],
  };

  Future<void> _showLevelUpDialog(String newLevel) async {
    final charClass = _canonicalState?['character_class'] as String? ?? 'Rogue';
    final existingSkills = (_canonicalState?['skills'] as Map?)?.keys.toList() ?? [];
    final allSkills = _classskills[charClass] ?? _classskills['Rogue']!;
    // Offer 3 skills the player doesn't already have
    final available = allSkills.where((s) => !existingSkills.contains(s['id'])).take(3).toList();
    if (available.isEmpty) return; // all skills learned

    final chosen = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F1219),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFC9A84C), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFC9A84C), size: 28),
              const SizedBox(height: 8),
              Text(
                'LEVEL $newLevel',
                style: const TextStyle(color: Color(0xFFC9A84C), fontSize: 18, letterSpacing: 3),
              ),
              const SizedBox(height: 4),
              const Text('Choose a new ability', style: TextStyle(color: Color(0xFF8898B0), fontSize: 12)),
              const SizedBox(height: 20),
              ...available.map((skill) => GestureDetector(
                onTap: () => Navigator.pop(ctx, skill),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2230),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2D3A4A)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(skill['name'] as String, style: const TextStyle(color: Color(0xFFC9A84C), fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 3),
                            Text(skill['desc'] as String, style: const TextStyle(color: Color(0xFF8898B0), fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF4A5A72), size: 18),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );

    if (chosen != null && mounted) {
      // Save skill to canonical_state
      final user = Supabase.instance.client.auth.currentUser!;
      final skills = Map<String, dynamic>.from((_canonicalState?['skills'] as Map?)?.cast<String, dynamic>() ?? {});
      skills[chosen['id'] as String] = {'name': chosen['name'], 'desc': chosen['desc'], 'unlocked_at_level': newLevel};
      await Supabase.instance.client
          .from('canonical_state')
          .update({'skills': skills})
          .eq('user_id', user.id)
          .eq('character_id', widget.characterId);
      await _loadCanonicalState();
    }
  }

  // ── SHOP MODAL ───────────────────────────────────────────────────

  static const _shopItems = [
    {'id': 'item_healing_salve', 'name': 'Healing Salve', 'desc': 'Restores 12 HP when used.', 'cost': 15, 'item_type': 'consumable', 'rarity': 'common'},
    {'id': 'item_mana_tonic', 'name': 'Mana Tonic', 'desc': 'Restores 10 MP when used.', 'cost': 18, 'item_type': 'consumable', 'rarity': 'common'},
    {'id': 'item_stamina_draught', 'name': 'Stamina Draught', 'desc': 'Restores 8 stamina when used.', 'cost': 12, 'item_type': 'consumable', 'rarity': 'common'},
    {'id': 'item_iron_ration', 'name': 'Iron Ration', 'desc': 'Trail food. Restores 5 HP.', 'cost': 5, 'item_type': 'consumable', 'rarity': 'common'},
    {'id': 'item_smoke_bomb', 'name': 'Smoke Bomb', 'desc': 'Escape any combat without a counter-attack.', 'cost': 25, 'item_type': 'consumable', 'rarity': 'rare'},
    {'id': 'item_revive_charm', 'name': 'Revive Charm', 'desc': 'Automatically revive at 10 HP when you fall.', 'cost': 60, 'item_type': 'consumable', 'rarity': 'legendary'},
  ];

  void _showShopModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1219),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFF1A2230)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final gold = _canonicalState?['gold'] as int? ?? 0;
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, color: Color(0xFFC9A84C), size: 18),
                      const SizedBox(width: 10),
                      const Text('MERCHANT', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 13, letterSpacing: 2)),
                      const Spacer(),
                      const Icon(Icons.monetization_on, color: Color(0xFFC9A84C), size: 14),
                      const SizedBox(width: 4),
                      Text('$gold gp', style: const TextStyle(color: Color(0xFFC9A84C), fontSize: 13)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF4A5A72), size: 18),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1A2230)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _shopItems.map((item) {
                      final cost = item['cost'] as int;
                      final canAfford = gold >= cost;
                      final rarityColor = {
                        'common': const Color(0xFF8898B0),
                        'rare': const Color(0xFF4A9EFF),
                        'legendary': const Color(0xFFC9A84C),
                      }[item['rarity'] as String] ?? const Color(0xFF8898B0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2230),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rarityColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: rarityColor, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'] as String, style: TextStyle(color: rarityColor, fontSize: 12, fontWeight: FontWeight.w500)),
                                  Text(item['desc'] as String, style: const TextStyle(color: Color(0xFF4A5A72), fontSize: 10)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${cost}g', style: TextStyle(color: canAfford ? const Color(0xFFC9A84C) : const Color(0xFF4A5A72), fontSize: 11)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: canAfford ? () async {
                                final user = Supabase.instance.client.auth.currentUser!;
                                final inv = List<Map<String, dynamic>>.from(
                                  ((_canonicalState?['inventory'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [])
                                );
                                inv.add({...item, 'quantity': 1});
                                final newGold = gold - cost;
                                await Supabase.instance.client
                                    .from('canonical_state')
                                    .update({'gold': newGold, 'inventory': inv})
                                    .eq('user_id', user.id)
                                    .eq('character_id', widget.characterId);
                                await _loadCanonicalState();
                                Navigator.pop(ctx);
                                setState(() {
                                  _log.add({'type': 'system', 'text': 'Purchased ${item['name']} for ${cost}g.'});
                                });
                              } : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: canAfford ? const Color(0xFF2D7DD2).withOpacity(0.2) : const Color(0xFF1A2230),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: canAfford ? const Color(0xFF2D7DD2) : const Color(0xFF2D3A4A)),
                                ),
                                child: Text('BUY', style: TextStyle(color: canAfford ? const Color(0xFF4A9EFF) : const Color(0xFF4A5A72), fontSize: 10, letterSpacing: 1)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Animated three-dot typing indicator
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        // Each dot lights up in sequence over the 900ms cycle
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (t - i * 0.25).clamp(0.0, 1.0);
            final opacity = phase < 0.5
                ? phase * 2
                : (1.0 - phase) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity.clamp(0.15, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC9A84C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

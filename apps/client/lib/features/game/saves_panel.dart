import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavesPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Future<void> Function() onLoaded;
  final String characterId;

  const SavesPanel({
    super.key,
    required this.onClose,
    required this.onLoaded,
    required this.characterId,
  });

  @override
  State<SavesPanel> createState() => _SavesPanelState();
}

class _SavesPanelState extends State<SavesPanel> {
  List<Map<String, dynamic>> _saves = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaves();
  }

  Future<void> _loadSaves() async {
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final response = await Supabase.instance.client.functions.invoke(
        'save_manager',
        body: {'action': 'LIST', 'user_id': user.id, 'character_id': widget.characterId},
      );
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _saves = (data['saves'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createSave() async {
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final now = DateTime.now();
      final saveName =
          'Save ${now.day}/${now.month} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      await Supabase.instance.client.functions.invoke(
        'save_manager',
        body: {
          'action': 'SAVE',
          'user_id': user.id,
          'character_id': widget.characterId,
          'save_name': saveName,
        },
      );
      await _loadSaves();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadSave(String saveId, String saveName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2230),
        title: const Text(
          'Load Save',
          style: TextStyle(color: Color(0xFFC9A84C)),
        ),
        content: Text(
          'Load "$saveName"? Your current progress will be replaced.',
          style: const TextStyle(color: Color(0xFFD4DCE8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF4A5A72))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Load',
                style: TextStyle(color: Color(0xFF4A9EFF))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.functions.invoke(
        'save_manager',
        body: {
          'action': 'LOAD',
          'user_id': user.id,
          'character_id': widget.characterId,
          'save_id': saveId,
        },
      );
      await widget.onLoaded();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteSave(String saveId, String saveName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2230),
        title: const Text(
          'Delete Save',
          style: TextStyle(color: Color(0xFFE05555)),
        ),
        content: Text(
          'Delete "$saveName"? This cannot be undone.',
          style: const TextStyle(color: Color(0xFFD4DCE8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF4A5A72))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE05555))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.functions.invoke(
        'save_manager',
        body: {
          'action': 'DELETE',
          'user_id': user.id,
          'character_id': widget.characterId,
          'save_id': saveId,
        },
      );
      await _loadSaves();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _exportSave(String saveId, String saveName) async {
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final response = await Supabase.instance.client.functions.invoke(
        'save_manager',
        body: {
          'action': 'EXPORT',
          'user_id': user.id,
          'character_id': widget.characterId,
          'save_id': saveId,
        },
      );
      final data = response.data;
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F1219),
            title: Text(
              'Export — $saveName',
              style: const TextStyle(color: Color(0xFFC9A84C), fontSize: 13),
            ),
            content: SizedBox(
              width: 500,
              height: 400,
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(
                    color: Color(0xFF8898B0),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: Color(0xFF4A5A72))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1219),
        border: Border(left: BorderSide(color: Color(0xFF1A2230))),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_error != null) _buildError(),
          Expanded(child: _buildSavesList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A2230))),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_outlined, color: Color(0xFFC9A84C), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'SAVES',
              style: TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 12,
                letterSpacing: 3,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _saving ? null : _createSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D7DD2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add, size: 14),
            label: const Text('Save', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF4A5A72), size: 18),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0A0A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE05555).withOpacity(0.3)),
      ),
      child: Text(
        _error!,
        style: const TextStyle(color: Color(0xFFE05555), fontSize: 11),
      ),
    );
  }

  Widget _buildSavesList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A9EFF)),
      );
    }

    if (_saves.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.save_outlined, color: Color(0xFF2D3A4A), size: 32),
            SizedBox(height: 8),
            Text(
              'No saves yet',
              style: TextStyle(color: Color(0xFF4A5A72), fontSize: 12),
            ),
            SizedBox(height: 4),
            Text(
              'Press Save to create one',
              style: TextStyle(color: Color(0xFF2D3A4A), fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _saves.length,
      itemBuilder: (context, i) => _buildSaveRow(_saves[i]),
    );
  }

  Widget _buildSaveRow(Map<String, dynamic> save) {
    final saveId = save['id'] as String;
    final saveName = save['save_name'] as String;
    final createdAt = DateTime.parse(save['created_at'] as String).toLocal();
    final timeStr =
        '${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2230),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2D3A4A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark_outline,
              color: Color(0xFF4A9EFF), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saveName,
                  style: const TextStyle(
                    color: Color(0xFFD4DCE8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Color(0xFF4A5A72),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restore, color: Color(0xFF4CAF82), size: 18),
            tooltip: 'Load',
            onPressed: () => _loadSave(saveId, saveName),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Color(0xFF4A9EFF), size: 18),
            tooltip: 'Export JSON',
            onPressed: () => _exportSave(saveId, saveName),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFF4A5A72), size: 18),
            tooltip: 'Delete',
            onPressed: () => _deleteSave(saveId, saveName),
          ),
        ],
      ),
    );
  }
}
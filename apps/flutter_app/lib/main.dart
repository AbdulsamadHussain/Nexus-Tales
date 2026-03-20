import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const NexusTalesApp());
}

class NexusTalesApp extends StatelessWidget {
  const NexusTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Tales',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF285C4D)),
        useMaterial3: true,
      ),
      home: const NexusTalesShell(),
    );
  }
}

class NexusTalesShell extends StatefulWidget {
  const NexusTalesShell({super.key});

  @override
  State<NexusTalesShell> createState() => _NexusTalesShellState();
}

class _NexusTalesShellState extends State<NexusTalesShell> {
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _backendUrlController =
      TextEditingController(text: 'http://localhost:3000');

  // Local draft state (never canonical)
  String? _latestRevisionId;
  Map<String, dynamic>? _latestResponse;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _actionController.dispose();
    _backendUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitTurn() async {
    final actionText = _actionController.text.trim();
    if (actionText.isEmpty) {
      setState(() {
        _errorMessage = 'Action cannot be empty.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backendUrl = _backendUrlController.text.trim();
      final url = Uri.parse('$backendUrl/v1/turns');

      // Generate deterministic client turn ID for this demo
      final clientTurnId =
          'flutter_turn_${DateTime.now().millisecondsSinceEpoch}';

      const playerId = 'flutter_player_001';
      const runId = 'flutter_run_001';
      const saveSlotId = 'flutter_slot_001';

      final requestBody = {
        'playerId': playerId,
        'runId': runId,
        'saveSlotId': saveSlotId,
        'clientTurnId': clientTurnId,
        'inputText': actionText,
        'sceneId': 'scene_nexus_hall',
        'sessionId': 'flutter_session_001',
        'contentSettings': {
          'violenceLevel': 'MEDIUM',
          'romanceEnabled': false,
          'horrorEnabled': false,
          'matureThemesEnabled': false,
          'betrayalEnabled': false,
          'customExclusions': [],
        },
        'difficultyMode': 'STANDARD',
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _latestRevisionId = responseData['revisionId'] as String?;
          _latestResponse = responseData;
          _isLoading = false;
          _actionController.clear();
        });
      } else {
        setState(() {
          _errorMessage =
              'Server error (${response.statusCode}): ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to submit turn: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexus Tales Phase 0'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Backend Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _backendUrlController,
                      decoration: InputDecoration(
                        hintText: 'http://localhost:3000',
                        border: OutlineInputBorder(),
                        labelText: 'Backend URL',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Turn Submission
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Action',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _actionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe your in-world action...',
                        border: OutlineInputBorder(),
                        labelText: 'Action',
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitTurn,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Turn'),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Authoritative Response Display
            if (_latestResponse != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authoritative Response',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _ResponseDetailsWidget(response: _latestResponse!),
                    ],
                  ),
                ),
              )
            else if (!_isLoading)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Submit an action to see the authoritative backend response.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResponseDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> response;

  const _ResponseDetailsWidget({required this.response});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow('Status', response['status'] as String?),
        _DetailRow('Revision ID', response['revisionId'] as String?),
        _DetailRow(
          'Route Category',
          response['routeCategory'] as String?,
        ),
        _DetailRow(
          'Safety Decision',
          response['policy']?['decision'] as String?,
        ),
        if (response['simulationResult'] != null) ...[
          const SizedBox(height: 12),
          Text(
            'Simulation Result',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            'Success Tier',
            response['simulationResult']?['successTier'] as String?,
          ),
          if (response['simulationResult']?['roll'] != null)
            _DetailRow(
              'Roll',
              '${response['simulationResult']?['roll']?['die']} + ${response['simulationResult']?['roll']?['modifier']} = ${response['simulationResult']?['roll']?['total']} vs ${response['simulationResult']?['roll']?['target']}',
            ),
        ],
        if ((response['events'] as List?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          Text(
            'Events (${(response['events'] as List).length})',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ...((response['events'] as List?)?.map((event) {
                final e = event as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Chip(
                    label: Text(e['eventType'] as String? ?? 'UNKNOWN_EVENT'),
                  ),
                );
              }).toList() ??
              []),
        ],
        if ((response['workerJobs'] as List?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 12),
          Text(
            'Worker Jobs Queued',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          ...((response['workerJobs'] as List?)?.map((job) {
                final j = job as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Chip(
                    label: Text(j['jobType'] as String? ?? 'UNKNOWN_JOB'),
                  ),
                );
              }).toList() ??
              []),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            value ?? '—',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';

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

class NexusTalesShell extends StatelessWidget {
  const NexusTalesShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexus Tales Phase 0'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          _PhaseCard(
            title: 'Contract-first foundation',
            body:
                'Canonical schemas live in the shared contracts package. Flutter avoids local duplicate DTOs and will consume generated API artifacts from the workspace.',
          ),
          SizedBox(height: 16),
          _PhaseCard(
            title: 'Authoritative backend shell',
            body:
                'Fastify exposes a mocked POST /v1/turns response so the client shell can be wired before simulation logic exists.',
          ),
          SizedBox(height: 16),
          _PhaseCard(
            title: 'State ownership rule',
            body:
                'Remote revision data is authoritative. Local presentation state and draft input stay client-side and never fabricate canonical truth.',
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(body),
          ],
        ),
      ),
    );
  }
}


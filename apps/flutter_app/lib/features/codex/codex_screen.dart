import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routing/riverpod_providers.dart';
import '../../app/theme/theme.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/index.dart';

class CodexScreen extends ConsumerWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(codexEntriesProvider);
    final codex = entries.isEmpty ? MockData.mockCodexEntries : entries;
    final selectedEntry = ref.watch(selectedCodexEntryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final filtered = codex
        .where((e) => e.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Codex', style: AppTypography.headingMedium),
        backgroundColor: AppColors.surfaceCard,
      ),
      body: Row(
        children: [
          // Left: Entry list
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    onChanged: (v) => ref
                        .read(searchQueryProvider.notifier)
                        .state = v,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      filled: true,
                      fillColor: AppColors.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return CodexEntryCard(
                        entry: entry,
                        isSelected: selectedEntry?.id == entry.id,
                        onTap: () => ref
                            .read(selectedCodexEntryProvider.notifier)
                            .state = entry,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right: Entry detail
          if (selectedEntry != null)
            Expanded(
              flex: 1,
              child: Container(
                color: AppColors.surfaceCard,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedEntry.title,
                          style: AppTypography.headingMedium),
                      Text(selectedEntry.category,
                          style: AppTypography.bodySmall),
                      const SizedBox(height: AppSpacing.lg),
                      Text(selectedEntry.content,
                          style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

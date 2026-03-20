import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routing/riverpod_providers.dart';
import '../../app/theme/theme.dart';
import '../../data/mock/mock_data.dart';
import '../../domain/models/game_models.dart';
import '../../shared/widgets/index.dart';

class SavesScreen extends ConsumerWidget {
  const SavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saves = ref.watch(saveSlotsProvider);
    final saveList = saves.isEmpty ? MockData.mockSaveSlots : saves;

    final manualSaves =
        saveList.where((s) => !s.isAutosave && !s.isCheckpoint).toList();
    final autosaves =
        saveList.where((s) => s.isAutosave && !s.isCheckpoint).toList();
    final checkpoints =
        saveList.where((s) => s.isCheckpoint).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Saves', style: AppTypography.headingMedium),
          backgroundColor: AppColors.surfaceCard,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Manual'),
              Tab(text: 'Autosave'),
              Tab(text: 'Checkpoints'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSavesList(manualSaves),
            _buildSavesList(autosaves),
            _buildSavesList(checkpoints),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Game saved!')),
            );
          },
          label: const Text('Save Game'),
          icon: const Icon(Icons.save),
        ),
      ),
    );
  }

  Widget _buildSavesList(List<SaveSlot> saves) {
    return saves.isEmpty
        ? Center(
            child: EmptyStateCard(
              icon: Icons.save,
              title: 'No saves',
              description: 'Create your first save to see it here.',
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: saves.length,
            itemBuilder: (context, index) {
              final save = saves[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(save.characterName,
                                style: AppTypography.headingSmall),
                            Text(save.location,
                                style: AppTypography.bodySmall),
                          ],
                        ),
                        if (save.isAutosave)
                          Chip(label: const Text('Autosave')),
                        if (save.isCheckpoint)
                          Chip(label: const Text('Checkpoint')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(save.currentChapter,
                        style: AppTypography.bodySmall),
                    Text(
                      'Rev. ${save.revisionNumber} • ${save.lastSavedAt.difference(DateTime.now()).inHours}h ago',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Load'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }
}

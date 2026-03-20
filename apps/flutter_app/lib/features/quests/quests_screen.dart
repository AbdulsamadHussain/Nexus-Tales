import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routing/riverpod_providers.dart';
import '../../app/theme/theme.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/index.dart';

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questListProvider);
    final questList = quests.isEmpty ? MockData.mockQuests : quests;
    final selectedQuest = ref.watch(selectedQuestProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Quests', style: AppTypography.headingMedium),
        backgroundColor: AppColors.surfaceCard,
      ),
      body: Row(
        children: [
          // Left: Quest list
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: questList.length,
              itemBuilder: (context, index) {
                final quest = questList[index];
                return QuestCard(
                  quest: quest,
                  isSelected: selectedQuest?.id == quest.id,
                  onTap: () => ref
                      .read(selectedQuestProvider.notifier)
                      .state = quest,
                );
              },
            ),
          ),
          // Right: Quest detail
          if (selectedQuest != null)
            Expanded(
              flex: 1,
              child: Container(
                color: AppColors.surfaceCard,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedQuest.title,
                          style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.md),
                      Text(selectedQuest.description,
                          style: AppTypography.bodySmall),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Objectives',
                          style: AppTypography.headingSmall),
                      ...selectedQuest.objectives
                          .asMap()
                          .entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Row(
                                  children: [
                                    Icon(
                                      e.key == selectedQuest.currentObjectiveIndex
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: AppColors.accentBronze,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(child: Text(e.value)),
                                  ],
                                ),
                              )),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Rewards',
                          style: AppTypography.headingSmall),
                      Text('${selectedQuest.rewardGold} Gold',
                          style: AppTypography.bodyMedium),
                      Text('${selectedQuest.rewardExperience} XP',
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

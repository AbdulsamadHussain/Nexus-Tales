import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routing/riverpod_providers.dart';
import '../../app/theme/theme.dart';
import '../../data/mock/mock_data.dart';
import '../../domain/models/game_models.dart';
import '../../shared/widgets/index.dart';

class CharacterSheetScreen extends ConsumerWidget {
  const CharacterSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(currentCharacterProvider) ?? MockData.mockCharacter;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Character', style: AppTypography.headingMedium),
          backgroundColor: AppColors.surfaceCard,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Combat'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(character),
            _buildCombatTab(character),
            _buildHistoryTab(character),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(PlayerCharacter character) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: character.name, subtitle: character.archetype),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Level ${character.level} • ${character.background}',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Core Stats',
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            children: character.stats.entries
                .map((entry) => StatPill(
                      label: entry.key.toUpperCase().substring(0, 3),
                      value: entry.value.toString(),
                      color: AppColors.accentBronze,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCombatTab(PlayerCharacter character) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Combat Stats', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.lg),
          StatPill(
            label: 'HP',
            value: '${character.healthPoints}/${character.maxHealthPoints}',
            color: AppColors.statusDanger,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(PlayerCharacter character) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Experience', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${character.experience} XP',
            style: AppTypography.headingMedium,
          ),
        ],
      ),
    );
  }
}

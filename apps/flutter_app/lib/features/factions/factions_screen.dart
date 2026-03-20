import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routing/riverpod_providers.dart';
import '../../app/theme/theme.dart';
import '../../data/mock/mock_data.dart';
import '../../domain/models/game_models.dart';

class FactionsScreen extends ConsumerWidget {
  const FactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factions = ref.watch(factionsProvider);
    final factionList = factions.isEmpty ? MockData.mockFactions : factions;
    final relationships = ref.watch(relationshipsProvider);
    final relList =
        relationships.isEmpty ? MockData.mockRelationships : relationships;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Factions & Relationships',
              style: AppTypography.headingMedium),
          backgroundColor: AppColors.surfaceCard,
          bottom: const TabBar(
            tabs: [Tab(text: 'Factions'), Tab(text: 'Relationships')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFactionsTab(factionList),
            _buildRelationshipsTab(relList),
          ],
        ),
      ),
    );
  }

  Widget _buildFactionsTab(List<Faction> factions) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: factions.length,
      itemBuilder: (context, index) {
        final faction = factions[index];
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
              Text(faction.name, style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(faction.description, style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Standing: ${faction.standing}',
                      style: AppTypography.bodyMedium),
                  Chip(label: Text(faction.tier.toUpperCase())),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRelationshipsTab(List<Relationship> relationships) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: relationships.length,
      itemBuilder: (context, index) {
        final rel = relationships[index];
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
              Text(rel.npcName, style: AppTypography.headingSmall),
              Text(rel.role, style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Text('Trust: ${rel.trustScore}', style: AppTypography.bodySmall),
              Text('Loyalty: ${rel.loyalty}',
                  style: AppTypography.bodySmall),
              Text('Fear: ${rel.fearLevel}',
                  style: AppTypography.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

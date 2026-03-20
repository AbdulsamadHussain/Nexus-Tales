import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../data/mock/mock_data.dart';
import '../../domain/models/game_models.dart';
import '../../shared/widgets/index.dart';

class CampaignSelectionScreen extends ConsumerWidget {
  const CampaignSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = MockData.mockCampaigns;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.surfaceCard,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nexus Tales',
                  style: AppTypography.displayLarge,
                ),
                Text(
                  'Select your campaign',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Campaign list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: campaigns.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final campaign = campaigns[index];
                return _buildCampaignCard(context, campaign);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, Campaign campaign) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.accentBronze.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign.title,
            style: AppTypography.headingMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            campaign.description,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Chip(label: Text(campaign.difficulty.toUpperCase())),
              const SizedBox(width: AppSpacing.md),
              Text(
                '~${campaign.estimatedLengthHours}h',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PrimaryButton(
                label: 'Continue Campaign',
                onPressed: () {
                  // Navigate to play screen with campaign loaded
                  context.push('/play');
                },
              ),
              SecondaryButton(
                label: 'New Game',
                onPressed: () {
                  // Navigate to character creation
                  context.push('/character-creation');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}


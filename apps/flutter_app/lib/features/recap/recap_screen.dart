import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../shared/widgets/index.dart';

class RecapScreen extends ConsumerWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Recap', style: AppTypography.headingMedium),
        backgroundColor: AppColors.surfaceCard,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Chapter 2: Whispers in the Dark',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Previously...',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRecapCard(
              'You entered The Raven\'s Threshold, a tavern shrouded in perpetual shadow. The air was thick with pipe smoke and ancient secrets.',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRecapCard(
              'A hooded figure watched from the corner, fingers wrapped around a goblet of burgundy. Their attention was unmistakably yours.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Key Events',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildEventItem('The Stolen Signet - Investigation began'),
            _buildEventItem('Lord Castian revealed his concerns'),
            _buildEventItem('Clue discovered in the Undercroft'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapCard(String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        text,
        style: AppTypography.bodyMedium,
      ),
    );
  }

  Widget _buildEventItem(String event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: AppColors.accentBronze),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(event, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

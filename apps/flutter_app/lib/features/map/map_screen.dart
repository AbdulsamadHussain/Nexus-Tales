import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('World Map', style: AppTypography.headingMedium),
        backgroundColor: AppColors.surfaceCard,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: AppColors.accentBronze),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Map coming soon',
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Discover locations to reveal the map',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

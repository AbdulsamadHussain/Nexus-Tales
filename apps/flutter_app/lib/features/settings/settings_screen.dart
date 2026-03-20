import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routing/riverpod_providers.dart';
import '../../app/theme/theme.dart';
import '../../shared/widgets/index.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentSettings = ref.watch(contentSettingsProvider);
    final accessibility = ref.watch(accessibilitySettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.headingMedium),
        backgroundColor: AppColors.surfaceCard,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gameplay
            SectionHeader(title: 'Gameplay'),
            const SizedBox(height: AppSpacing.lg),
            _buildToggleSetting(
              'Violence',
              contentSettings.violenceLevel == 'high',
              (value) {
                ref.read(contentSettingsProvider.notifier).state =
                    contentSettings.copyWith(
                  violenceLevel: value ? 'high' : 'medium',
                );
              },
            ),
            _buildToggleSetting(
              'Romance',
              contentSettings.romanceEnabled,
              (value) {
                ref.read(contentSettingsProvider.notifier).state =
                    contentSettings.copyWith(romanceEnabled: value);
              },
            ),
            _buildToggleSetting(
              'Horror',
              contentSettings.horrorEnabled,
              (value) {
                ref.read(contentSettingsProvider.notifier).state =
                    contentSettings.copyWith(horrorEnabled: value);
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Accessibility
            SectionHeader(title: 'Accessibility'),
            const SizedBox(height: AppSpacing.lg),
            _buildSliderSetting(
              'Text Size',
              accessibility.fontSizeMultiplier,
              1.0,
              1.5,
              (value) {
                ref.read(accessibilitySettingsProvider.notifier).state =
                    accessibility.copyWith(fontSizeMultiplier: value);
              },
            ),
            _buildToggleSetting(
              'High Contrast',
              accessibility.highContrast,
              (value) {
                ref.read(accessibilitySettingsProvider.notifier).state =
                    accessibility.copyWith(highContrast: value);
              },
            ),
            _buildToggleSetting(
              'Reduce Motion',
              accessibility.reduceMotion,
              (value) {
                ref.read(accessibilitySettingsProvider.notifier).state =
                    accessibility.copyWith(reduceMotion: value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentBronze,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.bodyMedium),
              Text(
                value.toStringAsFixed(1),
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: AppColors.accentBronze,
          ),
        ],
      ),
    );
  }
}

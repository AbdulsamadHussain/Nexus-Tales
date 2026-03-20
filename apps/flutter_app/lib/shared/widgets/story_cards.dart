import 'package:flutter/material.dart';
import '../../app/theme/theme.dart';

/// Narrative/story card for displaying story prose.
class StoryCard extends StatelessWidget {
  final String title;
  final String content;
  final String? source; // 'system', 'narration', 'event'
  final bool isHighlighted;

  const StoryCard({
    super.key,
    required this.title,
    required this.content,
    this.source,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.accentBronze.withValues(alpha: 0.1)
            : AppColors.surfaceCard,
        border: Border.all(
          color: isHighlighted
              ? AppColors.accentBronze.withValues(alpha: 0.5)
              : AppColors.divider,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headingSmall.copyWith(
                    color: isHighlighted
                        ? AppColors.accentBronze
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (source != null)
                Chip(
                  label: Text(
                    source!,
                    style: AppTypography.labelSmall,
                  ),
                  backgroundColor: AppColors.surfaceHover,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// NPC dialogue card.
class DialogueCard extends StatelessWidget {
  final String speakerName;
  final String speakerRole;
  final String dialogue;
  final String? portraitUrl;

  const DialogueCard({
    super.key,
    required this.speakerName,
    required this.speakerRole,
    required this.dialogue,
    this.portraitUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          left: BorderSide(
            color: AppColors.accentGold,
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (portraitUrl != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: AppColors.surfaceHover,
                  ),
                  // TODO: Replace with Image.network when ready
                  child: const Placeholder(),
                ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speakerName,
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.accentGold,
                    ),
                  ),
                  Text(
                    speakerRole,
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '"$dialogue"',
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Player action input card.
class PlayerActionCard extends StatelessWidget {
  final String actionSummary;
  final String outcome;
  final List<String> consequences;

  const PlayerActionCard({
    super.key,
    required this.actionSummary,
    required this.outcome,
    this.consequences = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceHover,
        border: Border(
          left: BorderSide(
            color: AppColors.accentBronze,
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You:',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.accentBronze,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            actionSummary,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            outcome,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (consequences.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Consequences:',
              style: AppTypography.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...consequences.map((consequence) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.statusDanger,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        consequence,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.statusDanger,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Roll/check result card.
class RollResultCard extends StatelessWidget {
  final String checkType; // 'Strength Check', 'Persuasion Roll', etc.
  final int difficulty;
  final int result;
  final String outcome; // 'Critical Success', 'Success', 'Failure', 'Critical Failure'
  final String description;

  const RollResultCard({
    super.key,
    required this.checkType,
    required this.difficulty,
    required this.result,
    required this.outcome,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    Color outcomeColor = AppColors.statusSuccess;
    if (outcome.contains('Failure') && outcome.contains('Critical')) {
      outcomeColor = AppColors.statusDanger;
    } else if (outcome.contains('Failure')) {
      outcomeColor = AppColors.statusWarning;
    } else if (outcome.contains('Critical')) {
      outcomeColor = AppColors.accentGold;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(
          color: outcomeColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            checkType,
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Result',
                    style: AppTypography.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$result',
                    style: AppTypography.displayMedium,
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'DC',
                    style: AppTypography.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$difficulty',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.statusWarning,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Column(
                  children: [
                    Text(
                      'Outcome',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        outcome,
                        style: AppTypography.labelLarge.copyWith(
                          color: outcomeColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Consequence summary card displaying state changes.
class ConsequenceCard extends StatelessWidget {
  final String title;
  final List<({String label, dynamic oldValue, dynamic newValue})> changes;
  final IconData? icon;

  const ConsequenceCard({
    super.key,
    required this.title,
    required this.changes,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceHover,
        border: Border.all(
          color: AppColors.statusWarning.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Icon(
                    icon,
                    color: AppColors.statusWarning,
                  ),
                ),
              Text(
                title,
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.statusWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...changes.map((change) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    change.label,
                    style: AppTypography.bodyMedium,
                  ),
                  Row(
                    children: [
                      Text(
                        '${change.oldValue}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppColors.accentIron,
                        ),
                      ),
                      Text(
                        '${change.newValue}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../app/theme/theme.dart';
import '../../domain/models/game_models.dart';

/// Quest card for displaying in quest list.
class QuestCard extends StatelessWidget {
  final Quest quest;
  final bool isSelected;
  final VoidCallback onTap;

  const QuestCard({
    super.key,
    required this.quest,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.statusInfo; // active
    if (quest.status == 'completed') {
      statusColor = AppColors.statusSuccess;
    } else if (quest.status == 'failed') {
      statusColor = AppColors.statusDanger;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBronze.withValues(alpha: 0.15)
              : AppColors.surfaceHover,
          border: Border.all(
            color: isSelected
                ? AppColors.accentBronze
                : AppColors.divider,
            width: isSelected ? 2 : 1,
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
                    quest.title,
                    style: AppTypography.headingSmall,
                  ),
                ),
                Chip(
                  label: Text(
                    quest.questType.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                    ),
                  ),
                  backgroundColor: quest.questType == 'main'
                      ? AppColors.accentGold.withValues(alpha: 0.3)
                      : AppColors.surfaceCard,
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              quest.description,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  quest.location,
                  style: AppTypography.captionSmall,
                ),
                if (quest.timeLimit > 0) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Icon(Icons.timer, size: 14, color: AppColors.statusWarning),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${quest.timeLimit}h remaining',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.statusWarning,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Codex entry card for discovered lore.
class CodexEntryCard extends StatelessWidget {
  final CodexEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const CodexEntryCard({
    super.key,
    required this.entry,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBronze.withValues(alpha: 0.15)
              : AppColors.surfaceCard,
          border: Border.all(
            color: isSelected
                ? AppColors.accentBronze
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.discovered ? entry.title : '???',
                    style: AppTypography.headingSmall.copyWith(
                      color: entry.discovered
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.category.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (entry.discovered)
              const Icon(
                Icons.check_circle,
                color: AppColors.statusSuccess,
              ),
            if (!entry.discovered)
              const Icon(
                Icons.lock,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Relationship card for NPCs.
class RelationshipCard extends StatelessWidget {
  final Relationship relationship;
  final VoidCallback? onTap;

  const RelationshipCard({
    super.key,
    required this.relationship,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color roleColor = _getRoleColor(relationship.role);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(
            color: roleColor.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              relationship.npcName,
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              relationship.role,
              style: AppTypography.labelSmall.copyWith(
                color: roleColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _RelationshipIndicator(
                  label: 'Trust',
                  value: relationship.trustScore,
                  color: AppColors.statusSuccess,
                ),
                _RelationshipIndicator(
                  label: 'Loyalty',
                  value: relationship.loyalty,
                  color: AppColors.accentBronze,
                ),
                _RelationshipIndicator(
                  label: 'Fear',
                  value: relationship.fearLevel,
                  color: AppColors.statusDanger,
                  isNegative: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ally':
        return AppColors.statusSuccess;
      case 'mentor':
        return AppColors.accentGold;
      case 'love':
        return AppColors.statusDanger;
      case 'rival':
        return AppColors.statusWarning;
      case 'enemy':
        return AppColors.statusDanger;
      default:
        return AppColors.accentIron;
    }
  }
}

class _RelationshipIndicator extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isNegative;

  const _RelationshipIndicator({
    required this.label,
    required this.value,
    required this.color,
    this.isNegative = true,
  });

  @override
  Widget build(BuildContext context) {
    String displayValue = '$value';
    if (isNegative && value < 0) {
      displayValue = '$value';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            displayValue,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Faction card for displaying faction standing.
class FactionCard extends StatelessWidget {
  final Faction faction;
  final bool isSelected;
  final VoidCallback? onTap;

  const FactionCard({
    super.key,
    required this.faction,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color tierColor = _getTierColor(faction.tier);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? tierColor.withValues(alpha: 0.15)
              : AppColors.surfaceCard,
          border: Border.all(
            color: isSelected ? tierColor : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              faction.name,
              style: AppTypography.headingSmall.copyWith(
                color: tierColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              faction.description,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Standing',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${faction.standing}',
                      style: AppTypography.headingSmall.copyWith(
                        color: tierColor,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    faction.tier.toUpperCase(),
                    style: AppTypography.labelSmall,
                  ),
                  backgroundColor: tierColor.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    side: BorderSide(
                      color: tierColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'hostile':
        return AppColors.statusDanger;
      case 'unfriendly':
        return AppColors.statusWarning;
      case 'neutral':
        return AppColors.accentIron;
      case 'friendly':
        return AppColors.statusSuccess;
      case 'allied':
        return AppColors.accentBronze;
      default:
        return AppColors.textSecondary;
    }
  }
}

/// Save slot card for displaying save information.
class SaveSlotCard extends StatelessWidget {
  final SaveSlot save;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback? onDelete;

  const SaveSlotCard({
    super.key,
    required this.save,
    this.isSelected = false,
    required this.onSelect,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentBronze.withValues(alpha: 0.15)
              : AppColors.surfaceCard,
          border: Border.all(
            color: isSelected
                ? AppColors.accentBronze
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        save.campaignTitle,
                        style: AppTypography.headingSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        save.characterName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (save.isCheckpoint)
                  const Chip(
                    label: Text('CHECKPOINT'),
                    backgroundColor: AppColors.accentGold,
                  ),
                if (save.isAutosave && !save.isCheckpoint)
                  const Chip(
                    label: Text('AUTOSAVE'),
                    backgroundColor: AppColors.statusInfo,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    save.location,
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rev ${save.revisionNumber}',
                  style: AppTypography.captionSmall,
                ),
                Text(
                  _formatDate(save.lastSavedAt),
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.statusDanger,
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

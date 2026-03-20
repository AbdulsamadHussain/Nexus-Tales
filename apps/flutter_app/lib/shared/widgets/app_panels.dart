import 'package:flutter/material.dart';
import '../../app/theme/theme.dart';

/// Standard container for content with dark fantasy styling.
class PanelContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderSide? borderSide;

  const PanelContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.onTap,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceCard,
          border: Border.all(
            color: borderSide?.color ?? AppColors.divider,
            width: borderSide?.width ?? 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: (elevation ?? 2) > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: elevation?.toDouble() ?? 2,
                    offset: Offset(0, elevation?.toDouble() ?? 2),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Standard section header with optional action button.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  final bool accentColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onActionTap,
    this.actionIcon,
    this.accentColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Icon(
                icon,
                color: accentColor
                    ? AppColors.accentBronze
                    : AppColors.textPrimary,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headingMedium.copyWith(
                    color: accentColor
                        ? AppColors.accentBronze
                        : AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      subtitle!,
                      style: AppTypography.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          if (onActionTap != null && actionIcon != null)
            IconButton(
              onPressed: onActionTap,
              icon: Icon(actionIcon),
            ),
        ],
      ),
    );
  }
}

/// A stat/value display pill.
class StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool emphasized;

  const StatPill({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.accentBronze.withValues(alpha: 0.2)
            : AppColors.surfaceHover,
        border: Border.all(
          color: color ?? AppColors.accentIron,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall,
          ),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: emphasized ? AppColors.accentBronze : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action chip with icon and label.
class QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSelected;

  const QuickActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      backgroundColor: isSelected
          ? AppColors.accentBronze
          : AppColors.surfaceHover,
      selectedColor: AppColors.accentBronze,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: isSelected
              ? AppColors.accentBronze
              : AppColors.divider,
        ),
      ),
    );
  }
}

/// Empty state display card.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.accentIron,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Warning banner for important alerts.
class WarningBanner extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onDismiss;

  const WarningBanner({
    super.key,
    required this.message,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.statusDanger.withValues(alpha: 0.2),
        border: Border(
          left: BorderSide(
            color: textColor ?? AppColors.statusDanger,
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Icon(
                icon,
                color: textColor ?? AppColors.statusDanger,
              ),
            ),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor ?? AppColors.statusDanger,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

/// Revision status badge showing save state.
class RevisionStatusBadge extends StatelessWidget {
  final String revisionId;
  final DateTime? timestamp;
  final String? status; // 'saved', 'saving', 'autosaved', 'checkpoint'

  const RevisionStatusBadge({
    super.key,
    required this.revisionId,
    this.timestamp,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.textSecondary;
    IconData statusIcon = Icons.info_outline;

    if (status == 'saved') {
      statusColor = AppColors.statusSuccess;
      statusIcon = Icons.check_circle;
    } else if (status == 'saving') {
      statusColor = AppColors.accentBronze;
      statusIcon = Icons.hourglass_bottom;
    } else if (status == 'autosaved') {
      statusColor = AppColors.statusInfo;
      statusIcon = Icons.cloud_done;
    } else if (status == 'checkpoint') {
      statusColor = AppColors.accentGold;
      statusIcon = Icons.flag_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              status ?? 'Rev $revisionId',
              style: AppTypography.labelSmall.copyWith(color: statusColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

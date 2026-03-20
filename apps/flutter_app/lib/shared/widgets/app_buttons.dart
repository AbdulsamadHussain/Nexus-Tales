import 'package:flutter/material.dart';
import '../../app/theme/theme.dart';

/// Primary action button with bronze accent.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  isEnabled
                      ? AppColors.textInverse
                      : AppColors.disabled,
                ),
              ),
            )
          : (icon != null ? Icon(icon) : const SizedBox.shrink()),
      label: Text(label),
    );
  }
}

/// Secondary action button with subtle styling.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(label),
    );
  }
}

/// Danger button for destructive actions (red/crimson).
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;

  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.statusDanger,
        side: BorderSide(
          color: AppColors.statusDanger.withValues(alpha: 0.5),
        ),
      ),
      child: Text(label),
    );
  }
}

/// Text button for tertiary actions.
class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.accentBronze,
        ),
      ),
    );
  }
}

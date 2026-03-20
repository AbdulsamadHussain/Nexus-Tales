import 'package:flutter/material.dart';

/// Premium dark fantasy design constants for Nexus Tales UI.
/// Respects the architecture's visual direction: elegant, readable, atmospheric.
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0A0A0A); // Near-black charcoal
  static const Color surfaceDark = Color(0xFF1A1A1A); // Deep surface
  static const Color surfaceCard = Color(0xFF242424); // Card base
  static const Color surfaceHover = Color(0xFF2E2E2E); // Interactive hover

  // Accents & Borders
  static const Color accentBronze = Color(0xFFB8860B); // Muted bronze
  static const Color accentGold = Color(0xFFC9A961); // Aged gold
  static const Color accentIron = Color(0xFF808080); // Iron gray
  static const Color accentAsh = Color(0xFF6B5E5E); // Ash gray

  // Functional
  static const Color textPrimary = Color(0xFFE8E8E8); // Parchment-gray readable
  static const Color textSecondary = Color(0xFFB0B0B0); // Muted text
  static const Color textTertiary = Color(0xFF808080); // Low emphasis
  static const Color textInverse = Color(0xFF1A1A1A); // On light backgrounds

  // Status & Alerts
  static const Color statusDanger = Color(0xFFAA3333); // Restrained crimson
  static const Color statusWarning = Color(0xFFCC8800); // Warning amber
  static const Color statusSuccess = Color(0xFF559955); // Muted green
  static const Color statusInfo = Color(0xFF4477AA); // Muted blue
  static const Color statusHeal = Color(0xFF669966); // Healing tint

  // Disabled / Inactive
  static const Color disabled = Color(0xFF4A4A4A); // Inactive button
  static const Color divider = Color(0xFF3A3A3A); // Border/divider

  // Transparency helpers
  static Color withAlpha(Color color, double alpha) =>
      color.withValues(alpha: alpha);
}

class AppSpacing {
  // Base unit: 4dp
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

class AppRadius {
  static const double none = 0.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 9999.0;
}

class AppTypography {
  // Display & Hero
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  // Headlines & Section titles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Labels & Buttons
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Captions
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: AppColors.textTertiary,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    height: 1.3,
    color: AppColors.textTertiary,
  );
}

class AppShadows {
  static const List<BoxShadow> smElevation = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> mdElevation = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lgElevation = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}

/// Border styles for consistent UI treatment
class AppBorders {
  static const BorderSide thin = BorderSide(
    color: AppColors.divider,
    width: 1,
  );

  static const BorderSide medium = BorderSide(
    color: AppColors.divider,
    width: 1.5,
  );

  static const BorderSide accent = BorderSide(
    color: AppColors.accentBronze,
    width: 1,
  );
}

/// Animation durations following Material standards
class AppDurations {
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration xShort = Duration(milliseconds: 100);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration xLong = Duration(milliseconds: 800);
}

/// Curvatures for animations
class AppCurves {
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve standard = Curves.easeInOutCubic;
}

/// Layout & responsive breakpoints
class AppBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
}

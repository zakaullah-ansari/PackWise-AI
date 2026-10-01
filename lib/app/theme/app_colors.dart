import 'package:flutter/material.dart';

/// PackWise AI "Dark Cyber-Glassmorphism" color palette.
///
/// All colors are defined once here and consumed via [AppTheme] /
/// `Theme.of(context)` — widgets should never hard-code a `Color(0x...)`
/// literal directly.
///
/// Syllabus mapping: Encapsulation, static const fields, design systems.
abstract final class AppColors {
  const AppColors._();

  /// Deep Navy Slate — primary app background.
  static const Color background = Color(0xFF0B0F19);

  /// Slightly lighter navy used for elevated surfaces/cards before the
  /// glassmorphic blur/opacity is applied on top.
  static const Color surface = Color(0xFF141A2A);

  /// Neon Teal — primary accent (CTAs, active states, highlights).
  static const Color primary = Color(0xFF00F2FE);

  /// Emerald Green — secondary accent (success states, eco/sustainability).
  static const Color secondary = Color(0xFF10B981);

  /// Semantic error/danger color.
  static const Color error = Color(0xFFEF4444);

  /// Semantic warning color (used for medium sustainability/barrier ratings).
  static const Color warning = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);

  /// 1px hairline border color for glass panels (10% opacity white).
  static const Color glassBorder = Color(0x1AFFFFFF);

  /// Fill color for frosted-glass containers (subtle white overlay).
  static const Color glassFill = Color(0x0DFFFFFF);

  /// Gradient used behind the splash logo / primary CTA buttons.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primary, secondary],
  );

  /// Returns a color representing a 0–100 sustainability/eco score, moving
  /// from [error] (poor) through [warning] to [secondary] (excellent).
  static Color forScore(double score) {
    if (score >= 75) return secondary;
    if (score >= 45) return warning;
    return error;
  }
}

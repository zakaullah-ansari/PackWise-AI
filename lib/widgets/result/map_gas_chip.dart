import 'package:flutter/material.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';

/// Displays a Modified Atmosphere Packaging (MAP) gas mix
/// (`CO2` / `O2` / `N2` percentages) as three compact chips.
///
/// Syllabus mapping: Stateless widgets, Layouts (Wrap), Map iteration.
class MapGasChip extends StatelessWidget {
  const MapGasChip({super.key, required this.gasRatioPercent});

  /// Expected keys: `co2`, `o2`, `n2` (percentages, ideally summing to 100).
  final Map<String, double> gasRatioPercent;

  static const Map<String, Color> _gasColors = <String, Color>{
    'co2': AppColors.secondary,
    'o2': AppColors.primary,
    'n2': AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final MapEntry<String, double> entry in gasRatioPercent.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(AppTheme.chipRadius),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _gasColors[entry.key] ?? AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key.toUpperCase()} ${entry.value.toStringAsFixed(1)}%',
                  style: AppTheme.monoStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

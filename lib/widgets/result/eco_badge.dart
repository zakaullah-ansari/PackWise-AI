import 'package:flutter/material.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';
import 'package:packwise_ai/data/mixins/sustainability_score_mixin.dart';

/// A compact pill badge showing a 0–100 sustainability score and its letter
/// [EcoGrade], color-coded via [AppColors.forScore].
///
/// Syllabus mapping: Stateless widgets, enums, conditional styling.
class EcoBadge extends StatelessWidget {
  const EcoBadge({super.key, required this.score, required this.grade});

  final double score;
  final EcoGrade grade;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.forScore(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.eco_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${grade.label} · ${score.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

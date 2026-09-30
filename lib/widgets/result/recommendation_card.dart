import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';
import 'package:packwise_ai/data/models/recommendation.dart';
import 'package:packwise_ai/widgets/result/eco_badge.dart';

/// A glassmorphic card summarizing one ranked [RecommendedMaterialResult],
/// shown in a scrollable list on [ResultView]. Tapping navigates to
/// [MaterialDetailView] for the full specification breakdown.
///
/// Accepts [animationIndex] to stagger each card's entrance animation,
/// giving the results list a polished, sequential reveal.
///
/// Syllabus mapping: Stateless widgets, Layouts, Animations
/// (`flutter_animate`), composition.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.result,
    required this.onTap,
    this.animationIndex = 0,
  });

  final RecommendedMaterialResult result;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final bool isTopPick = result.rank == 1;

    final Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isTopPick ? AppColors.primary.withOpacity(0.6) : AppColors.glassBorder,
          width: isTopPick ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _RankBadge(rank: result.rank),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      result.material.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.barrierRating.label,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              EcoBadge(score: result.sustainabilityScore, grade: result.ecoGrade),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  label: 'Predicted Shelf Life',
                  value: '${result.predictedShelfLifeDays} days',
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Thickness',
                  value: '${result.recommendedThicknessMicrons.toStringAsFixed(0)} µm',
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Confidence',
                  value: '${(result.confidenceScore * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.aiRationale,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                'View full specs',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.9),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: card,
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * animationIndex))
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(begin: 0.08, end: 0, duration: const Duration(milliseconds: 400));
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({super.key, required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: rank == 1 ? AppColors.primaryGradient : null,
        color: rank == 1 ? null : AppColors.glassFill,
        shape: BoxShape.circle,
        border: rank == 1 ? null : Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: rank == 1 ? const Color(0xFF001014) : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.monoStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

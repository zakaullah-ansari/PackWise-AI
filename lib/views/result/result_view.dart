import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:packwise_ai/app/routes/app_routes.dart';
import 'package:packwise_ai/app/routes/route_arguments.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';
import 'package:packwise_ai/data/models/recommendation.dart';
import 'package:packwise_ai/painters/shelf_life_gauge_painter.dart';
import 'package:packwise_ai/providers/auth_provider.dart';
import 'package:packwise_ai/providers/recommendation_provider.dart';
import 'package:packwise_ai/widgets/common/primary_button.dart';
import 'package:packwise_ai/widgets/result/recommendation_card.dart';

/// Displays the top-3 packaging recommendations for the most recent
/// [Recommendation], headlined by a [ShelfLifeGaugePainter] gauge comparing
/// the AI-predicted shelf life of the #1 pick against the user's desired
/// target.
///
/// Syllabus mapping: CustomPainter usage, Layouts, Animations, State
/// Management, Named Routing, Firebase Firestore (save-to-history action).
class ResultView extends StatelessWidget {
  const ResultView({super.key, required this.recommendation});

  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final RecommendedMaterialResult? topResult = recommendation.topResult;
    final double progress = topResult == null || recommendation.commodity.desiredShelfLifeDays == 0
        ? 0
        : topResult.predictedShelfLifeDays / recommendation.commodity.desiredShelfLifeDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(recommendation.commodity.name.isEmpty
            ? 'Recommendation'
            : recommendation.commodity.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            if (recommendation.isOfflineFallback) _offlineBadge(),
            Center(
              child: SizedBox(
                height: 140,
                width: 260,
                child: CustomPaint(
                  painter: ShelfLifeGaugePainter(progress: progress),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${topResult?.predictedShelfLifeDays ?? 0} days',
                            style: AppTheme.monoStyle(fontSize: 22, color: AppColors.textPrimary),
                          ),
                          Text(
                            'of ${recommendation.commodity.desiredShelfLifeDays} day target',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
            const SizedBox(height: 24),
            Text(
              'Top ${recommendation.materials.length} Recommended Materials',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            for (int i = 0; i < recommendation.materials.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RecommendationCard(
                  result: recommendation.materials[i],
                  animationIndex: i,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.materialDetail,
                    arguments: MaterialDetailArguments(
                      materialResult: recommendation.materials[i],
                      recommendation: recommendation,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _SaveAndRestartActions(recommendation: recommendation),
          ],
        ),
      ),
    );
  }

  Widget _offlineBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Offline Mode — heuristic recommendation (not AI-generated)',
              style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveAndRestartActions extends StatefulWidget {
  const _SaveAndRestartActions({super.key, required this.recommendation});
  final Recommendation recommendation;

  @override
  State<_SaveAndRestartActions> createState() => _SaveAndRestartActionsState();
}

class _SaveAndRestartActionsState extends State<_SaveAndRestartActions> {
  bool _isSaving = false;
  bool _hasSaved = false;

  Future<void> _save() async {
    final String? userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);
    final bool success = await context.read<RecommendationProvider>().saveToHistory(userId);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _hasSaved = success;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Saved to history.' : 'Could not save — please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (isAuthenticated)
          PrimaryButton(
            label: _hasSaved ? 'Saved ✓' : 'Save to History',
            icon: _hasSaved ? Icons.check_rounded : Icons.bookmark_add_outlined,
            isLoading: _isSaving,
            onPressed: _hasSaved ? null : _save,
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            context.read<RecommendationProvider>().reset();
            Navigator.of(context).popUntil(ModalRoute.withName(AppRoutes.home));
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          child: const Text('Start New Analysis'),
        ),
      ],
    );
  }
}

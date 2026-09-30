import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:packwise_ai/app/routes/app_routes.dart';
import 'package:packwise_ai/app/routes/route_arguments.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';
import 'package:packwise_ai/data/models/recommendation.dart';
import 'package:packwise_ai/providers/auth_provider.dart';
import 'package:packwise_ai/providers/history_provider.dart';
import 'package:packwise_ai/widgets/common/error_banner.dart';
import 'package:packwise_ai/widgets/common/loading_indicator.dart';

/// Real-time Firestore-backed history list, newest first.
///
/// Feeds [HistoryProvider.historyStream] directly into a [StreamBuilder] —
/// the canonical Flutter pattern for reactive, live-updating lists — rather
/// than manually buffering snapshots in a `ChangeNotifier` field.
///
/// Syllabus mapping: Streams (`StreamBuilder`), Firestore, Layouts
/// (`ListView.builder`), swipe-to-delete (`Dismissible`).
class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<HistoryProvider>().bindUser(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final HistoryProvider historyProvider = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recommendation History')),
      body: SafeArea(
        child: StreamBuilder<List<Recommendation>>(
          stream: historyProvider.historyStream,
          builder: (BuildContext context, AsyncSnapshot<List<Recommendation>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingIndicator(message: 'Loading history…'));
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: ErrorBanner(message: snapshot.error.toString()),
              );
            }

            final List<Recommendation> items = snapshot.data ?? const <Recommendation>[];
            if (items.isEmpty) {
              return const _EmptyHistoryState();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Recommendation recommendation = items[index];
                return Dismissible(
                  key: ValueKey<String>(recommendation.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
                  onDismissed: (_) => context.read<HistoryProvider>().delete(recommendation.id),
                  child: _HistoryTile(recommendation: recommendation),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({super.key, required this.recommendation});
  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final RecommendedMaterialResult? topResult = recommendation.topResult;
    final String dateLabel = DateFormat('MMM d, y · h:mm a').format(recommendation.generatedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.result,
          arguments: ResultViewArguments(recommendation: recommendation),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recommendation.commodity.name.isEmpty
                          ? 'Unnamed Commodity'
                          : recommendation.commodity.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topResult == null
                          ? 'No recommendation data'
                          : 'Top pick: ${topResult.material.displayName}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 4),
                    Text(dateLabel,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.inbox_outlined, color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No recommendations yet',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Run an analysis from the Home screen and save it to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

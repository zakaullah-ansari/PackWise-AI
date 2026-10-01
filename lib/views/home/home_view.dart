import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:packwise_ai/app/routes/app_routes.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';
import 'package:packwise_ai/core/constants/api_constants.dart';
import 'package:packwise_ai/core/constants/app_constants.dart';
import 'package:packwise_ai/providers/auth_provider.dart';

/// The post-login dashboard: greets the user, surfaces whether the app is
/// running in live-AI or offline mode, and provides the two primary
/// navigation actions (new recommendation / history).
///
/// Uses [MediaQuery]/[LayoutBuilder] to switch between a single-column
/// layout (phones) and a two-column grid (tablets/desktop web) for the
/// quick-action cards.
///
/// Syllabus mapping: Layouts, MediaQuery, Named Routing, State Management.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final String displayName = auth.user?.displayName?.trim().isNotEmpty == true
        ? auth.user!.displayName!.trim()
        : (auth.user?.email?.split('@').first ?? 'there');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth > 640;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Welcome, $displayName 👋',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate().fadeIn(),
                  const SizedBox(height: 6),
                  const Text(
                    'Get science-backed packaging recommendations in seconds.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (!ApiConstants.hasApiKey) const _OfflineModeNotice(),
                  const SizedBox(height: 24),
                  isWide
                      ? Row(
                          children: <Widget>[
                            Expanded(child: _quickActionCard(context, isPrimary: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _historyCard(context)),
                          ],
                        )
                      : Column(
                          children: <Widget>[
                            _quickActionCard(context, isPrimary: true),
                            const SizedBox(height: 16),
                            _historyCard(context),
                          ],
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _quickActionCard(BuildContext context, {required bool isPrimary}) {
    return _ActionCard(
      icon: Icons.science_rounded,
      title: 'New Recommendation',
      subtitle: 'Analyze a commodity and get AI-powered packaging matches.',
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.inputForm),
      highlighted: isPrimary,
    );
  }

  Widget _historyCard(BuildContext context) {
    return _ActionCard(
      icon: Icons.history_rounded,
      title: 'View History',
      subtitle: 'Revisit past recommendations saved to your account.',
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.history),
      highlighted: false,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.highlighted,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color: highlighted ? AppColors.primary.withOpacity(0.5) : AppColors.glassBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: highlighted ? AppColors.primaryGradient : null,
                  color: highlighted ? null : AppColors.glassFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: highlighted ? const Color(0xFF001014) : AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }
}

class _OfflineModeNotice extends StatelessWidget {
  const _OfflineModeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No Gemini API key configured — recommendations will use the '
              'offline rules engine.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

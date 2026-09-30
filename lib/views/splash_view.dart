import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:packwise_ai/app/routes/app_routes.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/core/constants/app_constants.dart';
import 'package:packwise_ai/providers/auth_provider.dart';

/// The app's entry screen: shows an animated brand splash while Firebase
/// Auth resolves whether a user is already signed in, then redirects to
/// [AppRoutes.home] or [AppRoutes.login] accordingly.
///
/// Navigation only fires once BOTH a minimum dwell time has elapsed (so the
/// branding animation is never skipped on a fast device) AND
/// [AuthProvider.status] has resolved out of [AuthStatus.unknown] — a small
/// but important race-condition fix that naive "just delay 2 seconds" splash
/// screens usually get wrong.
///
/// Syllabus mapping: Named Routing, Animations, StatefulWidget lifecycle,
/// Streams (indirectly, via the AuthProvider listener).
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late final AuthProvider _authProvider;
  bool _minimumDurationElapsed = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _authProvider.addListener(_tryNavigate);

    Future<void>.delayed(AppConstants.splashMinimumDuration, () {
      _minimumDurationElapsed = true;
      _tryNavigate();
    });

    // In case auth state was already resolved before this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());
  }

  void _tryNavigate() {
    if (_hasNavigated || !mounted || !_minimumDurationElapsed) return;
    if (_authProvider.status == AuthStatus.unknown) return;

    _hasNavigated = true;
    final String destination =
        _authProvider.status == AuthStatus.authenticated ? AppRoutes.home : AppRoutes.login;
    Navigator.of(context).pushReplacementNamed(destination);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_tryNavigate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_rounded, size: 44, color: Color(0xFF001014)),
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 500))
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 28),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
          ],
        ),
      ),
    );
  }
}

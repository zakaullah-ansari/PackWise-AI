import 'package:flutter/material.dart';
import 'package:packwise_ai/app/routes/app_routes.dart';
import 'package:packwise_ai/app/routes/route_arguments.dart';
import 'package:packwise_ai/app/theme/app_colors.dart';
import 'package:packwise_ai/views/auth/login_view.dart';
import 'package:packwise_ai/views/auth/signup_view.dart';
import 'package:packwise_ai/views/history/history_view.dart';
import 'package:packwise_ai/views/home/home_view.dart';
import 'package:packwise_ai/views/input/input_form_view.dart';
import 'package:packwise_ai/views/material_detail/material_detail_view.dart';
import 'package:packwise_ai/views/result/result_view.dart';
import 'package:packwise_ai/views/splash_view.dart';

/// Central `onGenerateRoute` implementation for PackWise AI.
///
/// Using a single generator function (rather than a static `routes` map)
/// lets us validate/typed-cast [RouteSettings.arguments] before construction
/// and gracefully degrade to an in-app "route not found" screen instead of a
/// framework assertion crash if a caller ever passes the wrong argument type
/// or an unknown route name.
///
/// Syllabus mapping: Named Routing (`onGenerateRoute`), defensive
/// programming / Exception Handling at the navigation boundary.
abstract final class RouteGenerator {
  const RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _build(const SplashView(), settings);

      case AppRoutes.login:
        return _build(const LoginView(), settings);

      case AppRoutes.signup:
        return _build(const SignupView(), settings);

      case AppRoutes.home:
        return _build(const HomeView(), settings);

      case AppRoutes.inputForm:
        return _build(const InputFormView(), settings);

      case AppRoutes.history:
        return _build(const HistoryView(), settings);

      case AppRoutes.result:
        final Object? args = settings.arguments;
        if (args is ResultViewArguments) {
          return _build(ResultView(recommendation: args.recommendation), settings);
        }
        return _errorRoute(settings, 'Missing recommendation data for Result screen.');

      case AppRoutes.materialDetail:
        final Object? args = settings.arguments;
        if (args is MaterialDetailArguments) {
          return _build(
            MaterialDetailView(
              materialResult: args.materialResult,
              recommendation: args.recommendation,
            ),
            settings,
          );
        }
        return _errorRoute(settings, 'Missing material data for Detail screen.');

      default:
        return _errorRoute(settings, 'No route defined for "${settings.name}".');
    }
  }

  static Route<dynamic> _build(Widget child, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);
  }

  /// Friendly in-app 404 screen — keeps navigation mistakes (e.g. a typo'd
  /// route name introduced during future development) from crashing the
  /// whole app with a raw Flutter assertion.
  static Route<dynamic> _errorRoute(RouteSettings settings, String message) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

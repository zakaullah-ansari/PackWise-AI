import 'package:flutter/material.dart';
import 'package:packwise_ai/app/routes/app_routes.dart';
import 'package:packwise_ai/app/routes/route_generator.dart';
import 'package:packwise_ai/app/theme/app_theme.dart';
import 'package:packwise_ai/core/constants/app_constants.dart';

/// The root [MaterialApp] widget for PackWise AI.
///
/// Deliberately thin: all provider registration happens in `main.dart`
/// (above this widget in the tree) so `PackWiseApp` itself only owns
/// app-level concerns — theme and routing.
///
/// Syllabus mapping: Named Routing (`onGenerateRoute`), Theming.
class PackWiseApp extends StatelessWidget {
  const PackWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}

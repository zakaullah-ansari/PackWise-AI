import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:packwise_ai/app/app.dart';
import 'package:packwise_ai/core/utils/logger.dart';
import 'package:packwise_ai/firebase_options.dart';
import 'package:packwise_ai/providers/auth_provider.dart';
import 'package:packwise_ai/providers/history_provider.dart';
import 'package:packwise_ai/providers/recommendation_provider.dart';

/// Application entry point.
///
/// Initializes Firebase (best-effort — see the try/catch below) before
/// registering every MVVM [ChangeNotifier] provider at the root of the
/// widget tree via [MultiProvider], then launches [PackWiseApp].
///
/// Syllabus mapping: App bootstrapping, Firebase initialization, State
/// Management (Provider composition root), Exception Handling.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, stackTrace) {
    // A missing/placeholder Firebase configuration should never prevent the
    // app from launching — Auth/Firestore-dependent screens will simply show
    // their own error states, and packaging recommendations still work via
    // the Gemini API + offline fallback engine regardless of Firebase.
    AppLogger.error(
      'Firebase initialization failed — Auth/Firestore features will be '
      'unavailable until a real Firebase project is configured '
      '(run `flutterfire configure`).',
      error: e,
      stackTrace: stackTrace,
    );
  }

  runApp(
    MultiProvider(
      // Note: no explicit `List<...>` type argument here — Dart infers
      // `List<SingleChildWidget>` from `MultiProvider.providers`'s parameter
      // type, which is exactly what the `provider` package expects.
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<RecommendationProvider>(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider<HistoryProvider>(create: (_) => HistoryProvider()),
      ],
      child: const PackWiseApp(),
    ),
  );
}

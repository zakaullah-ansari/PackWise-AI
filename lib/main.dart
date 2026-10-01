import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:packwise_ai/app/app.dart';
import 'package:packwise_ai/core/utils/logger.dart';
import 'package:packwise_ai/firebase_options.dart';
import 'package:packwise_ai/providers/auth_provider.dart';
import 'package:packwise_ai/providers/history_provider.dart';
import 'package:packwise_ai/providers/recommendation_provider.dart';

/// Application entry point.
///
/// Loads local `.env` configuration (best-effort), initializes Firebase
/// (also best-effort — see the try/catch below) before registering every
/// MVVM [ChangeNotifier] provider at the root of the widget tree via
/// [MultiProvider], then launches [PackWiseApp].
///
/// Syllabus mapping: App bootstrapping, Firebase initialization, State
/// Management (Provider composition root), Exception Handling.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Optional convenience layer on top of --dart-define; see
    // ApiConstants.geminiApiKey and .env.example. A missing `.env` file
    // (e.g. a fresh clone before `cp .env.example .env`) is expected and
    // completely harmless — the app simply falls back to --dart-define or
    // fully offline mode.
    await dotenv.load(fileName: '.env');
  } catch (e, stackTrace) {
    AppLogger.info(
      'No .env file loaded (this is fine — use --dart-define=GEMINI_API_KEY=... '
      'instead, or run fully offline).',
      error: e,
      stackTrace: stackTrace,
    );
  }

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

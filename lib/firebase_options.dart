// File generated in the style of the FlutterFire CLI (`flutterfire configure`).
//
// ⚠️ IMPORTANT — before running this app against a real Firebase project:
//   1. Create/select a Firebase project at https://console.firebase.google.com
//   2. Run `flutterfire configure` from the repo root — it will OVERWRITE
//      this file with your project's real API keys and app IDs.
//   3. Never commit real production secrets from this file if the repo is
//      public; `google-services.json` / `GoogleService-Info.plist` are
//      already git-ignored (see `.gitignore`).
//
// The placeholder values below are non-functional and exist only so the
// project compiles out-of-the-box for code review / static analysis before
// a real Firebase project is attached.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux — '
          'run `flutterfire configure` to add Firebase support for this '
          'platform, or run PackWise AI in offline mode without Firebase.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: 'YOUR_FIREBASE_APP_ID',
    messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    authDomain: 'YOUR_FIREBASE_AUTH_DOMAIN',
    storageBucket: 'YOUR_FIREBASE_STORAGE_BUCKET',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: 'YOUR_FIREBASE_APP_ID',
    messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: 'YOUR_FIREBASE_APP_ID',
    messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_STORAGE_BUCKET',
    iosBundleId: 'com.packwise.ai',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: 'YOUR_FIREBASE_APP_ID',
    messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    storageBucket: 'YOUR_FIREBASE_STORAGE_BUCKET',
    iosBundleId: 'com.packwise.ai',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    appId: 'YOUR_FIREBASE_APP_ID',
    messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    authDomain: 'YOUR_FIREBASE_AUTH_DOMAIN',
    storageBucket: 'YOUR_FIREBASE_STORAGE_BUCKET',
  );
}

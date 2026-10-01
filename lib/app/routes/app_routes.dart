/// Named route string constants for PackWise AI.
///
/// Using a constants class (rather than raw string literals scattered across
/// `Navigator.pushNamed(...)` calls) prevents typo-related routing bugs and
/// gives IDE autocomplete for every screen in the app.
///
/// Syllabus mapping: Named Routing.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String inputForm = '/input-form';
  static const String result = '/result';
  static const String history = '/history';
  static const String materialDetail = '/material-detail';
}

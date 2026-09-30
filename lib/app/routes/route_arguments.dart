import 'package:packwise_ai/data/models/recommendation.dart';

/// Typed navigation argument bundles for PackWise AI's named routes.
///
/// Kept in their own file (rather than inside `route_generator.dart`) so
/// that Views can depend on the *argument shape* without also depending on
/// the route generator itself — avoiding an unnecessary circular import
/// between `route_generator.dart` (which imports every View to build its
/// routes) and the Views (which need these argument types to call
/// `Navigator.pushNamed`).
///
/// Syllabus mapping: Named Routing, clean dependency direction.
library;

/// Arguments for [AppRoutes.result].
class ResultViewArguments {
  const ResultViewArguments({required this.recommendation});
  final Recommendation recommendation;
}

/// Arguments for [AppRoutes.materialDetail].
class MaterialDetailArguments {
  const MaterialDetailArguments({
    required this.materialResult,
    required this.recommendation,
  });

  final RecommendedMaterialResult materialResult;
  final Recommendation recommendation;
}

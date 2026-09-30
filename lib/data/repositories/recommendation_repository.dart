import 'package:packwise_ai/core/errors/app_exception.dart';
import 'package:packwise_ai/core/errors/failure.dart';
import 'package:packwise_ai/core/utils/logger.dart';
import 'package:packwise_ai/data/mixins/validation_mixin.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';
import 'package:packwise_ai/data/models/recommendation.dart';
import 'package:packwise_ai/services/firestore_service.dart';
import 'package:packwise_ai/services/gemini_service.dart';
import 'package:packwise_ai/services/local_fallback_service.dart';
import 'package:uuid/uuid.dart';

/// Orchestrates the full "get a packaging recommendation" use case: validate
/// input → call Gemini → parse → (on any failure) transparently fall back to
/// the offline rules engine → optionally persist to Firestore.
///
/// This is the single seam between the UI/Provider layer and every data
/// source (network AI, local heuristics, cloud database) — [providers]
/// never talk to [GeminiService]/[FirestoreService] directly.
///
/// Mixes in [ValidationMixin] to reuse the same cross-field business-rule
/// checks that would otherwise need to be duplicated here.
///
/// Syllabus mapping: Repository pattern, Mixins, async/await, Exception
/// Handling, Dart 3 sealed-class `Result` pattern matching.
class RecommendationRepository with ValidationMixin {
  RecommendationRepository({
    GeminiService? geminiService,
    LocalFallbackService? fallbackService,
    FirestoreService? firestoreService,
    Uuid? uuid,
  })  : _gemini = geminiService ?? GeminiService(),
        _fallback = fallbackService ?? LocalFallbackService(),
        _firestore = firestoreService ?? FirestoreService(),
        _uuid = uuid ?? Uuid();

  final GeminiService _gemini;
  final LocalFallbackService _fallback;
  final FirestoreService _firestore;
  final Uuid _uuid;

  /// Requests a recommendation for [commodity].
  ///
  /// Always resolves to a [Success] containing *some* [Recommendation]
  /// (either AI-generated or the offline heuristic) unless the input itself
  /// is invalid, in which case a [ValidationFailure] is returned so the UI
  /// can point the user back at the form instead of pretending to succeed.
  Future<Result<Recommendation>> getRecommendation(FoodCommodity commodity) async {
    try {
      ensureCommodityIsValid(commodity);
    } on ValidationException catch (e) {
      return Result<Recommendation>.failure(Failure.fromException(e));
    }

    try {
      final Map<String, dynamic> rawJson = await _gemini.generateRecommendation(commodity);
      final Recommendation recommendation = Recommendation.fromGeminiJson(
        id: _uuid.v4(),
        commodity: commodity,
        json: rawJson,
      );

      if (recommendation.materials.isEmpty) {
        throw const ParsingException(
          'The AI response did not contain any usable recommendations.',
        );
      }
      return Result<Recommendation>.success(recommendation);
    } on AppException catch (e, stackTrace) {
      AppLogger.warning(
        'Gemini recommendation failed (${e.runtimeType}: ${e.message}); '
        'falling back to the offline rules engine.',
        error: e,
        stackTrace: stackTrace,
      );
      return Result<Recommendation>.success(
        _fallback.generateOfflineRecommendation(commodity),
      );
    } catch (e, stackTrace) {
      // Any truly unexpected error still degrades gracefully to offline
      // mode rather than surfacing a dead end to the user.
      AppLogger.error(
        'Unexpected error generating recommendation; falling back offline.',
        error: e,
        stackTrace: stackTrace,
      );
      return Result<Recommendation>.success(
        _fallback.generateOfflineRecommendation(commodity),
      );
    }
  }

  /// Persists [recommendation] against [userId] and returns the saved
  /// document id.
  Future<Result<String>> saveRecommendation(
    Recommendation recommendation, {
    required String userId,
  }) async {
    try {
      final String id = await _firestore.saveRecommendation(
        recommendation.copyWith(userId: userId),
      );
      return Result<String>.success(id);
    } on AppException catch (e) {
      return Result<String>.failure(Failure.fromException(e));
    } catch (e) {
      return Result<String>.failure(Failure.fromException(e));
    }
  }

  /// Real-time history stream for [userId] — errors surface through the
  /// stream itself so a `StreamBuilder`'s `snapshot.hasError` can react.
  Stream<List<Recommendation>> historyStream(String userId) {
    return _firestore.streamHistory(userId);
  }

  Future<Recommendation?> getRecommendationById(String id) {
    return _firestore.getRecommendationById(id);
  }

  Future<Result<bool>> deleteRecommendation(String id) async {
    try {
      await _firestore.deleteRecommendation(id);
      return const Result<bool>.success(true);
    } on AppException catch (e) {
      return Result<bool>.failure(Failure.fromException(e));
    }
  }

  /// Releases resources held by the underlying [GeminiService].
  void dispose() => _gemini.dispose();
}

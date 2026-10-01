import 'package:flutter/foundation.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';
import 'package:packwise_ai/data/models/recommendation.dart';
import 'package:packwise_ai/data/repositories/recommendation_repository.dart';

/// View-state machine for the recommendation request lifecycle.
///
/// Syllabus mapping: Enums as a finite state machine.
enum RecommendationViewState { idle, loading, success, error }

/// MVVM ViewModel driving [InputFormView] and [ResultView].
///
/// Holds the in-progress/last [FoodCommodity] draft (so the form can be
/// re-opened with previous values) and the resulting [Recommendation] (AI or
/// offline), exposing a single [RecommendationViewState] the View can switch
/// on to render loading/error/success UI.
///
/// Syllabus mapping: State Management (ChangeNotifier), async/await,
/// Exception Handling (via [Result] pattern matching).
class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider({RecommendationRepository? repository})
      : _repository = repository ?? RecommendationRepository();

  final RecommendationRepository _repository;

  RecommendationViewState _state = RecommendationViewState.idle;
  Recommendation? _recommendation;
  String? _errorMessage;
  FoodCommodity _draftCommodity = FoodCommodity.empty();

  RecommendationViewState get state => _state;
  Recommendation? get recommendation => _recommendation;
  String? get errorMessage => _errorMessage;
  FoodCommodity get draftCommodity => _draftCommodity;
  bool get isLoading => _state == RecommendationViewState.loading;

  /// Updates the in-progress form draft without triggering an AI request —
  /// used by [InputFormView] as the user edits sliders/fields.
  void updateDraft(FoodCommodity commodity) {
    _draftCommodity = commodity;
    notifyListeners();
  }

  /// Submits [commodity] to the repository (Gemini, with automatic offline
  /// fallback) and updates [state]/[recommendation]/[errorMessage].
  Future<void> requestRecommendation(FoodCommodity commodity) async {
    if (_state == RecommendationViewState.loading) return; // avoid double-submit
    _draftCommodity = commodity;
    _state = RecommendationViewState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getRecommendation(commodity);
    result.when(
      onSuccess: (Recommendation recommendation) {
        _recommendation = recommendation;
        _state = RecommendationViewState.success;
      },
      onFailure: (failure) {
        _errorMessage = failure.message;
        _state = RecommendationViewState.error;
      },
    );
    notifyListeners();
  }

  /// Persists [_recommendation] for [userId]. Returns `true` on success.
  Future<bool> saveToHistory(String userId) async {
    final Recommendation? current = _recommendation;
    if (current == null) return false;
    final result = await _repository.saveRecommendation(current, userId: userId);
    return result.isSuccess;
  }

  /// Resets the provider back to its initial idle state, e.g. after the user
  /// navigates away from the Result screen back to Home.
  void reset() {
    _state = RecommendationViewState.idle;
    _recommendation = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}

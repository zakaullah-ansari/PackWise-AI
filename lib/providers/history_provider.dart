import 'package:flutter/foundation.dart';
import 'package:packwise_ai/data/models/recommendation.dart';
import 'package:packwise_ai/data/repositories/recommendation_repository.dart';

/// MVVM ViewModel scoping the Firestore recommendation-history real-time
/// stream to the currently signed-in user.
///
/// Deliberately thin: it does *not* buffer the stream's data itself (that
/// would mean maintaining a second source of truth). Instead it exposes a
/// ready-to-consume [Stream] via [historyStream], which [HistoryView] feeds
/// directly into a `StreamBuilder` — the textbook Streams UI pattern.
///
/// Syllabus mapping: State Management (ChangeNotifier) composed with
/// Streams, Firestore real-time updates.
class HistoryProvider extends ChangeNotifier {
  HistoryProvider({RecommendationRepository? repository})
      : _repository = repository ?? RecommendationRepository();

  final RecommendationRepository _repository;
  String? _userId;

  /// Call once the signed-in user's id is known (typically from
  /// `AuthProvider.user!.uid`) before building the `StreamBuilder`.
  void bindUser(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    notifyListeners();
  }

  /// Real-time history stream for the currently bound user, newest first.
  /// Returns an empty stream if no user has been bound yet (e.g. the widget
  /// briefly rebuilds before [bindUser] is called).
  Stream<List<Recommendation>> get historyStream {
    final String? userId = _userId;
    if (userId == null) return const Stream<List<Recommendation>>.empty();
    return _repository.historyStream(userId);
  }

  Future<void> delete(String recommendationId) async {
    await _repository.deleteRecommendation(recommendationId);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:packwise_ai/core/constants/app_constants.dart';
import 'package:packwise_ai/core/errors/app_exception.dart';
import 'package:packwise_ai/core/utils/logger.dart';
import 'package:packwise_ai/data/models/recommendation.dart';

/// Wraps all Cloud Firestore CRUD + real-time stream access behind a small,
/// testable interface.
///
/// Every public method here converts a Firebase-specific error
/// ([FirebaseException]) — or any other unexpected error, including
/// "Firebase has not been initialized" — into our own [FirestoreException]
/// so upper layers never need to `import 'package:cloud_firestore/cloud_firestore.dart'`.
///
/// [_firestore] resolves [FirebaseFirestore.instance] **lazily** (see the
/// identical rationale documented on [AuthService._firebaseAuth]): merely
/// *constructing* a [FirestoreService] must never throw, otherwise
/// [RecommendationRepository]'s default constructor — created unconditionally
/// at app startup — would crash the app before any screen could render when
/// Firebase isn't configured.
///
/// Syllabus mapping: Firestore, Streams, async/await, Exception Handling
/// (defensive lazy initialization).
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _injectedFirestore = firestore;

  final FirebaseFirestore? _injectedFirestore;

  FirebaseFirestore get _firestore => _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _recommendations =>
      _firestore.collection(FirestoreCollections.recommendations);

  /// Persists [recommendation] and returns its Firestore document id.
  Future<String> saveRecommendation(Recommendation recommendation) async {
    try {
      final DocumentReference<Map<String, dynamic>> doc =
          _recommendations.doc(recommendation.id);
      await doc.set(recommendation.toFirestore());
      return doc.id;
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to save recommendation', error: e, stackTrace: stackTrace);
      throw FirestoreException('Could not save this recommendation: ${e.message}', cause: e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error saving recommendation', error: e, stackTrace: stackTrace);
      throw FirestoreException(
        'Could not save this recommendation — is Firebase configured?',
        cause: e,
      );
    }
  }

  /// Real-time stream of a user's recommendation history, most-recent first.
  ///
  /// Emits a [FirestoreException] onto the stream (instead of letting a raw
  /// [FirebaseException]/other error propagate) so a [StreamBuilder] can
  /// render a friendly error state. Because [_firestore] is only evaluated
  /// when this getter runs (not at construction time), a misconfigured
  /// Firebase project surfaces as a caught stream error here rather than an
  /// app-startup crash.
  Stream<List<Recommendation>> streamHistory(String userId) {
    try {
      return _recommendations
          .where('userId', isEqualTo: userId)
          .orderBy('generatedAt', descending: true)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                Recommendation.fromFirestore(doc.data()))
            .toList();
      }).handleError((Object error, StackTrace stackTrace) {
        AppLogger.error('History stream error', error: error, stackTrace: stackTrace);
        throw FirestoreException('Could not load history.', cause: error);
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'Could not open history stream — is Firebase configured?',
        error: e,
        stackTrace: stackTrace,
      );
      return Stream<List<Recommendation>>.error(
        FirestoreException('Could not load history — is Firebase configured?', cause: e),
      );
    }
  }

  /// Fetches a single recommendation by id (used for deep-linking / sharing).
  Future<Recommendation?> getRecommendationById(String id) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _recommendations.doc(id).get();
      if (!doc.exists) return null;
      return Recommendation.fromFirestore(doc.data()!);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to fetch recommendation $id', error: e, stackTrace: stackTrace);
      throw FirestoreException('Could not load this recommendation.', cause: e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error fetching recommendation $id', error: e, stackTrace: stackTrace);
      throw FirestoreException('Could not load this recommendation.', cause: e);
    }
  }

  /// Deletes a recommendation document by id.
  Future<void> deleteRecommendation(String id) async {
    try {
      await _recommendations.doc(id).delete();
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.error('Failed to delete recommendation $id', error: e, stackTrace: stackTrace);
      throw FirestoreException('Could not delete this recommendation.', cause: e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error deleting recommendation $id', error: e, stackTrace: stackTrace);
      throw FirestoreException('Could not delete this recommendation.', cause: e);
    }
  }
}

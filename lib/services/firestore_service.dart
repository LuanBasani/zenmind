import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';
import '../models/saved_quote_model.dart';

/// Service class that handles all Firestore interactions for ZenMind.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Quote of the Day
  // ---------------------------------------------------------------------------

  /// Returns a stream that emits the daily [Quote] whenever it changes in
  /// Firestore (/dailyContent/quoteOfTheDay).
  Stream<Quote?> quoteOfTheDayStream() {
    return _db
        .collection('dailyContent')
        .doc('quoteOfTheDay')
        .withConverter<Quote>(
          fromFirestore: (snap, _) => Quote.fromFirestore(snap),
          toFirestore: (quote, _) => quote.toMap(),
        )
        .snapshots()
        .map((snap) => snap.data());
  }

  // ---------------------------------------------------------------------------
  // Saved Quotes
  // ---------------------------------------------------------------------------

  /// Saves [quote] to the authenticated user's personal collection.
  ///
  /// Path: /users/{uid}/savedQuotes/{auto-id}
  Future<void> saveQuote(String uid, Quote quote) async {
    try {
      await _db.collection('users').doc(uid).collection('savedQuotes').add({
        'text': quote.text,
        'author': quote.author,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Falha ao salvar a citação: $e');
    }
  }

  /// Returns a stream of the user's saved quotes, ordered by [savedAt] desc.
  Stream<List<SavedQuote>> savedQuotesStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('savedQuotes')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => SavedQuote.fromFirestore(doc))
              .toList(),
        );
  }

  /// Deletes the saved quote with [quoteId] for user [uid].
  Future<void> deleteQuote(String uid, String quoteId) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('savedQuotes')
          .doc(quoteId)
          .delete();
    } catch (e) {
      throw Exception('Falha ao deletar a citação: $e');
    }
  }

  /// Returns true if the given [quote]'s text is already saved for user [uid].
  Future<bool> isQuoteSaved(String uid, Quote quote) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('savedQuotes')
          .where('text', isEqualTo: quote.text)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing Firestore database operations
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get userId => _auth.currentUser?.uid;

  /// Initialize Firestore (enable offline persistence, etc.)
  static Future<void> initialize() async {
    try {
      // Enable offline persistence for better UX
      await _firestore.enableNetwork();
    } catch (e) {
      // Error initializing Firestore - using debugPrint for development
      // In production, consider using a proper logging framework
      assert(() {
        // ignore: avoid_print
        print('Error initializing Firestore: $e');
        return true;
      }());
    }
  }

  /// Reference to user's decks collection
  static CollectionReference<Map<String, dynamic>> getDecksCollection() {
    if (userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(userId).collection('decks');
  }

  /// Reference to user's cards collection
  static CollectionReference<Map<String, dynamic>> getCardsCollection(
    String deckId,
  ) {
    if (userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId)
        .collection('cards');
  }

  /// Reference to user's study sessions collection
  static CollectionReference<Map<String, dynamic>>
      getStudySessionsCollection() {
    if (userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('studySessions');
  }

  /// Reference to user's statistics document
  static DocumentReference<Map<String, dynamic>> getStatisticsDocument() {
    if (userId == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('statistics');
  }

  /// Clear all user data
  static Future<void> clearAllUserData() async {
    if (userId == null) throw Exception('User not authenticated');

    // Delete all decks and their cards
    final decksSnapshot = await getDecksCollection().get();
    for (var deckDoc in decksSnapshot.docs) {
      await deckDoc.reference.delete();

      // Delete all cards in this deck
      final cardsSnapshot = await getCardsCollection(deckDoc.id).get();
      for (var cardDoc in cardsSnapshot.docs) {
        await cardDoc.reference.delete();
      }
    }

    // Delete all study sessions
    final sessionsSnapshot = await getStudySessionsCollection().get();
    for (var sessionDoc in sessionsSnapshot.docs) {
      await sessionDoc.reference.delete();
    }

    // Delete statistics
    await getStatisticsDocument().delete();
  }
}

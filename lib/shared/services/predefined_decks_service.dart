import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import './predefined_decks_loader.dart';

/// Service to create predefined decks for new users
class PredefinedDecksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  PredefinedDecksService({required this.userId});

  CollectionReference<Map<String, dynamic>> get _decksCollection {
    return _firestore.collection('users').doc(userId).collection('decks');
  }

  /// Check if user has any decks
  Future<bool> hasExistingDecks() async {
    final snapshot = await _decksCollection.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Create all predefined decks with their cards from CSV files
  Future<void> createPredefinedDecks() async {
    // Check if decks already exist
    if (await hasExistingDecks()) {
      return;
    }

    final loader = PredefinedDecksLoader(userId: userId);
    final decksData = await loader.loadPredefinedDecksData();

    // Import all predefined decks
    for (final deckData in decksData) {
      try {
        final deckInfo = deckData['info'] as Map<String, dynamic>;
        final deckName = deckInfo['name'] as String;
        await loader.importPredefinedDeck(deckName);
      } catch (e) {
        developer.log('Error creating predefined deck: $e');
      }
    }
  }
}

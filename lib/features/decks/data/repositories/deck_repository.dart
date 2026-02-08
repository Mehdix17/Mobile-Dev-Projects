import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck_model.dart';

class DeckRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  DeckRepository({required this.userId});

  CollectionReference<Map<String, dynamic>> get _decksCollection {
    return _firestore.collection('users').doc(userId).collection('decks');
  }

  Future<void> createDeck(DeckModel deck) async {
    final docRef = _decksCollection.doc();
    final newDeck = deck.copyWith(id: docRef.id);
    await docRef.set(newDeck.toJson());
  }

  Future<DeckModel?> getDeck(String id) async {
    final doc = await _decksCollection.doc(id).get();
    if (!doc.exists) return null;
    return DeckModel.fromJson(doc.data()!, doc.id);
  }

  Future<List<DeckModel>> getAllDecks() async {
    final snapshot =
        await _decksCollection.orderBy('updatedAt', descending: true).get();
    return snapshot.docs
        .map((doc) => DeckModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<DeckModel>> searchDecks(String query) async {
    final snapshot = await _decksCollection.get();
    return snapshot.docs
        .map((doc) => DeckModel.fromJson(doc.data(), doc.id))
        .where((deck) => deck.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<DeckModel>> getDecksByParentId(String? parentId) async {
    final snapshot =
        await _decksCollection.where('parentId', isEqualTo: parentId).get();
    return snapshot.docs
        .map((doc) => DeckModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateDeck(DeckModel deck) async {
    final updatedDeck = deck.copyWith(updatedAt: DateTime.now());
    await _decksCollection.doc(deck.id).update(updatedDeck.toJson());
  }

  Future<void> updateDeckCardCounts(
    String deckId, {
    int? cardCount,
    int? newCardCount,
    int? dueCardCount,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (cardCount != null) updates['cardCount'] = cardCount;
    if (newCardCount != null) updates['newCardCount'] = newCardCount;
    if (dueCardCount != null) updates['dueCardCount'] = dueCardCount;

    await _decksCollection.doc(deckId).update(updates);
  }

  Future<void> deleteDeck(String id) async {
    await _decksCollection.doc(id).delete();
  }

  Future<void> toggleStarred(String deckId, bool isStarred) async {
    await _decksCollection.doc(deckId).update({
      'isStarred': isStarred,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> publishDeck(String deckId, bool isPublished) async {
    await _decksCollection.doc(deckId).update({
      'isPublished': isPublished,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<List<DeckModel>> getStarredDecks() async {
    final snapshot = await _decksCollection
        .where('isStarred', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => DeckModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<DeckModel>> getPublishedDecks() async {
    final snapshot = await _decksCollection
        .where('isPublished', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => DeckModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<int> getDeckCount() async {
    final snapshot = await _decksCollection.count().get();
    return snapshot.count ?? 0;
  }

  Future<List<DeckModel>> getRecentDecks({int limit = 5}) async {
    final snapshot = await _decksCollection
        .orderBy('lastStudiedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => DeckModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Stream<List<DeckModel>> watchAllDecks() {
    return _decksCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DeckModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<DeckModel?> watchDeck(String id) {
    return _decksCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DeckModel.fromJson(doc.data()!, doc.id);
    });
  }
}

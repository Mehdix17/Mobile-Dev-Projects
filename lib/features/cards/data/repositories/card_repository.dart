import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';

class CardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  CardRepository({required this.userId});

  CollectionReference<Map<String, dynamic>> _cardsCollection(String deckId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId)
        .collection('cards');
  }

  Future<void> createCard(CardModel card) async {
    final docRef = _cardsCollection(card.deckId).doc();
    final newCard = card.copyWith(id: docRef.id);
    await docRef.set(newCard.toJson());
  }

  Future<CardModel?> getCard(String deckId, String id) async {
    final doc = await _cardsCollection(deckId).doc(id).get();
    if (!doc.exists) return null;
    return CardModel.fromJson(doc.data()!, doc.id);
  }

  Future<List<CardModel>> getCardsByDeckId(String deckId) async {
    final snapshot = await _cardsCollection(deckId).get();
    return snapshot.docs
        .map((doc) => CardModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<CardModel>> getDueCards(String deckId) async {
    final now = DateTime.now();
    final snapshot = await _cardsCollection(deckId)
        .where('nextReviewDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();
    return snapshot.docs
        .map((doc) => CardModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<CardModel>> getNewCards(String deckId, {int limit = 20}) async {
    final snapshot = await _cardsCollection(deckId)
        .where('status', isEqualTo: CardStatus.newCard.name)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => CardModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateCard(CardModel card) async {
    if (card.id.isEmpty) {
      throw ArgumentError('Card ID cannot be empty');
    }
    if (card.deckId.isEmpty) {
      throw ArgumentError('Deck ID cannot be empty');
    }
    final updatedCard = card.copyWith(updatedAt: DateTime.now());
    await _cardsCollection(card.deckId)
        .doc(card.id)
        .update(updatedCard.toJson());
  }

  Future<void> deleteCard(String deckId, String id) async {
    await _cardsCollection(deckId).doc(id).delete();
  }

  Future<void> deleteAllCardsInDeck(String deckId) async {
    final batch = _firestore.batch();
    final snapshot = await _cardsCollection(deckId).get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> batchCreateCards(List<CardModel> cards) async {
    if (cards.isEmpty) return;
    final batch = _firestore.batch();
    for (var card in cards) {
      final docRef = _cardsCollection(card.deckId).doc();
      final newCard = card.copyWith(id: docRef.id);
      batch.set(docRef, newCard.toJson());
    }
    await batch.commit();
  }

  Future<int> getCardCount(String deckId) async {
    final snapshot = await _cardsCollection(deckId).count().get();
    return snapshot.count ?? 0;
  }

  /// Get all cards across all decks for the user
  Future<List<CardModel>> getAllUserCards() async {
    final decksSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .get();

    final List<CardModel> allCards = [];

    for (var deckDoc in decksSnapshot.docs) {
      final cardsSnapshot = await _cardsCollection(deckDoc.id).get();
      final cards = cardsSnapshot.docs
          .map((doc) => CardModel.fromJson(doc.data(), doc.id))
          .toList();
      allCards.addAll(cards);
    }

    return allCards;
  }

  /// Get card counts by status across all decks
  Future<Map<CardStatus, int>> getCardCountsByStatus() async {
    final allCards = await getAllUserCards();

    final counts = <CardStatus, int>{
      CardStatus.newCard: 0,
      CardStatus.learning: 0,
      CardStatus.review: 0,
      CardStatus.mastered: 0,
    };

    for (var card in allCards) {
      counts[card.status] = (counts[card.status] ?? 0) + 1;
    }

    return counts;
  }

  Stream<List<CardModel>> watchCards(String deckId) {
    return _cardsCollection(deckId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CardModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<CardModel?> watchCard(String deckId, String id) {
    return _cardsCollection(deckId).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CardModel.fromJson(doc.data()!, doc.id);
    });
  }

  Future<List<CardModel>> searchCards(String deckId, String query) async {
    // Note: Firestore doesn't support full-text search natively
    // This is a simple prefix match on front field
    final snapshot = await _cardsCollection(deckId).get();
    final cards = snapshot.docs
        .map((doc) => CardModel.fromJson(doc.data(), doc.id))
        .where(
          (card) =>
              card.front.toLowerCase().contains(query.toLowerCase()) ||
              card.back.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return cards;
  }
}

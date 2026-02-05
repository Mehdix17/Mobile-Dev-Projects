import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/card_model.dart';
import '../../data/repositories/card_repository.dart';
import '../../../decks/data/repositories/deck_repository.dart';
import '../../../decks/presentation/providers/deck_provider.dart';

String _getUserId() {
  return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
}

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(userId: _getUserId());
});

final _deckRepositoryForCardsProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(userId: _getUserId());
});

final cardsProvider =
    FutureProvider.family<List<CardModel>, String>((ref, deckId) async {
  final repository = ref.watch(cardRepositoryProvider);
  return await repository.getCardsByDeckId(deckId);
});

final dueCardsProvider =
    FutureProvider.family<List<CardModel>, String>((ref, deckId) async {
  final repository = ref.watch(cardRepositoryProvider);
  return await repository.getDueCards(deckId);
});

final cardProvider =
    FutureProvider.family<CardModel?, (String, String)>((ref, params) async {
  final repository = ref.watch(cardRepositoryProvider);
  return await repository.getCard(params.$1, params.$2);
});

final cardSearchProvider =
    FutureProvider.family<List<CardModel>, (String, String)>(
        (ref, params) async {
  final repository = ref.watch(cardRepositoryProvider);
  return await repository.searchCards(params.$1, params.$2);
});

final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(cardRepositoryProvider);
  final deckRepository = ref.watch(_deckRepositoryForCardsProvider);

  try {
    // Get all decks
    final decks = await deckRepository.getAllDecks();
    final allTags = <String>{};

    // Get cards from all decks and collect unique tags
    for (final deck in decks) {
      final cards = await repository.getCardsByDeckId(deck.id);
      for (final card in cards) {
        allTags.addAll(card.tags);
      }
    }

    return allTags.toList()..sort();
  } catch (e) {
    return [];
  }
});

class CardNotifier extends StateNotifier<AsyncValue<List<CardModel>>> {
  final CardRepository _repository;
  final DeckRepository _deckRepository;
  final String deckId;
  final Ref _ref;

  CardNotifier(this._repository, this._deckRepository, this.deckId, this._ref)
      : super(const AsyncValue.loading()) {
    loadCards();
  }

  Future<void> loadCards() async {
    state = const AsyncValue.loading();
    try {
      final cards = await _repository.getCardsByDeckId(deckId);
      state = AsyncValue.data(cards);
      // Update deck counts on initial load
      await _updateDeckCounts();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _updateDeckCounts() async {
    try {
      final cards = await _repository.getCardsByDeckId(deckId);
      final now = DateTime.now();
      final dueCount = cards
          .where(
            (c) =>
                c.nextReviewDate.isBefore(now) ||
                c.nextReviewDate.isAtSameMomentAs(now),
          )
          .length;
      final newCount =
          cards.where((c) => c.status == CardStatus.newCard).length;

      await _deckRepository.updateDeckCardCounts(
        deckId,
        cardCount: cards.length,
        newCardCount: newCount,
        dueCardCount: dueCount,
      );

      // Invalidate deck provider to refresh UI
      _ref.invalidate(deckProvider(deckId));
      _ref.invalidate(decksProvider);
    } catch (e) {
      // Log but don't throw - this is a secondary operation
      assert(() {
        // ignore: avoid_print
        print('Error updating deck counts: $e');
        return true;
      }());
    }
  }

  Future<void> createCard(CardModel card) async {
    try {
      await _repository.createCard(card);
      await loadCards();
      await _updateDeckCounts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCard(CardModel card) async {
    try {
      await _repository.updateCard(card);
      await loadCards();
      await _updateDeckCounts();
      // Invalidate the individual card provider to refresh card detail screen
      _ref.invalidate(cardProvider((deckId, card.id)));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _repository.deleteCard(deckId, cardId);
      await loadCards();
      await _updateDeckCounts();
    } catch (e) {
      rethrow;
    }
  }
}

final cardListProvider = StateNotifierProvider.family<CardNotifier,
    AsyncValue<List<CardModel>>, String>(
  (ref, deckId) {
    final repository = ref.watch(cardRepositoryProvider);
    final deckRepository = ref.watch(_deckRepositoryForCardsProvider);
    return CardNotifier(repository, deckRepository, deckId, ref);
  },
);

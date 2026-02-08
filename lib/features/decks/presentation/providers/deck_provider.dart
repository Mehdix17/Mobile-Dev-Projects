import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/deck_model.dart';
import '../../data/repositories/deck_repository.dart';

String _getUserId() {
  return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
}

final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(userId: _getUserId());
});

final decksProvider = FutureProvider<List<DeckModel>>((ref) async {
  final repository = ref.watch(deckRepositoryProvider);
  return await repository.getAllDecks();
});

final rootDecksProvider = FutureProvider<List<DeckModel>>((ref) async {
  final repository = ref.watch(deckRepositoryProvider);
  return await repository.getDecksByParentId(null);
});

final deckProvider =
    FutureProvider.family<DeckModel?, String>((ref, deckId) async {
  final repository = ref.watch(deckRepositoryProvider);
  return await repository.getDeck(deckId);
});

final recentDecksProvider = FutureProvider<List<DeckModel>>((ref) async {
  final repository = ref.watch(deckRepositoryProvider);
  return await repository.getRecentDecks(limit: 5);
});

final deckSearchProvider =
    FutureProvider.family<List<DeckModel>, String>((ref, query) async {
  final repository = ref.watch(deckRepositoryProvider);
  return await repository.searchDecks(query);
});

class DeckNotifier extends StateNotifier<AsyncValue<List<DeckModel>>> {
  final DeckRepository _repository;
  final Ref _ref;

  DeckNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadDecks();
  }

  Future<void> loadDecks() async {
    state = const AsyncValue.loading();
    try {
      final decks = await _repository.getAllDecks();
      state = AsyncValue.data(decks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<DeckModel?> createDeck(DeckModel deck) async {
    try {
      await _repository.createDeck(deck);
      await loadDecks();
      return deck;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDeck(DeckModel deck) async {
    try {
      await _repository.updateDeck(deck);
      await loadDecks();
      // Invalidate the individual deck provider to refresh deck detail screen
      _ref.invalidate(deckProvider(deck.id));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDeck(String deckId) async {
    try {
      await _repository.deleteDeck(deckId);
      await loadDecks();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleStarred(String deckId, bool isStarred) async {
    try {
      await _repository.toggleStarred(deckId, isStarred);
      await loadDecks();
      _ref.invalidate(deckProvider(deckId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> publishDeck(String deckId, bool isPublished) async {
    try {
      await _repository.publishDeck(deckId, isPublished);
      await loadDecks();
      _ref.invalidate(deckProvider(deckId));
    } catch (e) {
      rethrow;
    }
  }
}

final deckListProvider =
    StateNotifierProvider<DeckNotifier, AsyncValue<List<DeckModel>>>(
  (ref) {
    final repository = ref.watch(deckRepositoryProvider);
    return DeckNotifier(repository, ref);
  },
);

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
      // Optimistic local removal
      state.whenData((decks) {
        state = AsyncValue.data(
          decks.where((d) => d.id != deckId).toList(),
        );
      });
    } catch (e) {
      await loadDecks(); // fallback
      rethrow;
    }
  }

  Future<void> toggleStarred(String deckId, bool isStarred) async {
    try {
      await _repository.toggleStarred(deckId, isStarred);
      // Optimistic local update
      state.whenData((decks) {
        state = AsyncValue.data(
          decks
              .map((d) => d.id == deckId ? d.copyWith(isStarred: isStarred) : d)
              .toList(),
        );
      });
      _ref.invalidate(deckProvider(deckId));
    } catch (e) {
      await loadDecks();
      rethrow;
    }
  }

  Future<void> publishDeck(String deckId, bool isPublished) async {
    try {
      await _repository.publishDeck(deckId, isPublished);
      // Optimistic local update
      state.whenData((decks) {
        state = AsyncValue.data(
          decks
              .map(
                (d) =>
                    d.id == deckId ? d.copyWith(isPublished: isPublished) : d,
              )
              .toList(),
        );
      });
      _ref.invalidate(deckProvider(deckId));
    } catch (e) {
      await loadDecks();
      rethrow;
    }
  }

  /// Bulk toggle star without reloading after each one
  Future<void> bulkToggleStar(List<String> deckIds, List<bool> values) async {
    for (var i = 0; i < deckIds.length; i++) {
      await _repository.toggleStarred(deckIds[i], values[i]);
    }
    // Single local state update
    state.whenData((decks) {
      final idToValue = Map.fromIterables(deckIds, values);
      state = AsyncValue.data(
        decks
            .map(
              (d) => idToValue.containsKey(d.id)
                  ? d.copyWith(isStarred: idToValue[d.id]!)
                  : d,
            )
            .toList(),
      );
    });
  }

  /// Bulk publish without reloading after each one
  Future<void> bulkPublish(List<String> deckIds) async {
    for (final id in deckIds) {
      await _repository.publishDeck(id, true);
    }
    state.whenData((decks) {
      final idSet = deckIds.toSet();
      state = AsyncValue.data(
        decks
            .map(
              (d) => idSet.contains(d.id) ? d.copyWith(isPublished: true) : d,
            )
            .toList(),
      );
    });
  }

  /// Bulk delete without reloading after each one
  Future<void> bulkDelete(List<String> deckIds) async {
    for (final id in deckIds) {
      await _repository.deleteDeck(id);
    }
    state.whenData((decks) {
      final idSet = deckIds.toSet();
      state = AsyncValue.data(
        decks.where((d) => !idSet.contains(d.id)).toList(),
      );
    });
  }
}

final deckListProvider =
    StateNotifierProvider<DeckNotifier, AsyncValue<List<DeckModel>>>(
  (ref) {
    final repository = ref.watch(deckRepositoryProvider);
    return DeckNotifier(repository, ref);
  },
);

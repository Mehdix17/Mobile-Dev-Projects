import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/statistics_model.dart';
import '../../data/repositories/statistics_repository.dart';
import '../../../cards/data/repositories/card_repository.dart';
import '../../../cards/data/models/card_model.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  return StatisticsRepository(userId: userId);
});

final cardRepositoryForStatsProvider = Provider<CardRepository>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  return CardRepository(userId: userId);
});

final statisticsProvider = FutureProvider<StatisticsModel>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return await repository.getStatistics();
});

final refreshedStatisticsProvider =
    FutureProvider<StatisticsModel>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return await repository.getStatistics();
});

class StatisticsNotifier extends StateNotifier<AsyncValue<StatisticsModel>> {
  final StatisticsRepository _repository;
  final CardRepository _cardRepository;

  StatisticsNotifier(this._repository, this._cardRepository)
      : super(const AsyncValue.loading()) {
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      // First sync card counts from actual cards
      await _syncCardCounts();

      // Then load the updated statistics
      final stats = await _repository.getStatistics();
      if (mounted) {
        state = AsyncValue.data(stats);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refreshStatistics() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      // Sync card counts first
      await _syncCardCounts();

      // Then load statistics
      final stats = await _repository.getStatistics();
      if (mounted) {
        state = AsyncValue.data(stats);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Sync card counts from actual cards in all decks
  Future<void> _syncCardCounts() async {
    try {
      final cardCounts = await _cardRepository.getCardCountsByStatus();
      final allCards = await _cardRepository.getAllUserCards();

      await _repository.updateCardCounts(
        totalCards: allCards.length,
        cardsNew: cardCounts[CardStatus.newCard] ?? 0,
        cardsLearning: cardCounts[CardStatus.learning] ?? 0,
        cardsMastered: cardCounts[CardStatus.mastered] ?? 0,
        cardsReview: cardCounts[CardStatus.review] ?? 0,
      );
    } catch (e) {
      // If sync fails, just log it but don't fail the whole operation
      developer.log('Failed to sync card counts: $e');
    }
  }
}

final statisticsNotifierProvider =
    StateNotifierProvider<StatisticsNotifier, AsyncValue<StatisticsModel>>(
        (ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  final cardRepository = ref.watch(cardRepositoryForStatsProvider);
  return StatisticsNotifier(repository, cardRepository);
});

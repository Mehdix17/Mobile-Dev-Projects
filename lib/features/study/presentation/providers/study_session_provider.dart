import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/study_session_model.dart';
import '../../data/repositories/study_repository.dart';
import '../../../cards/data/models/card_model.dart';
import '../../../cards/data/repositories/card_repository.dart';
import '../../../cards/presentation/providers/card_provider.dart';
import '../../../statistics/data/repositories/statistics_repository.dart';
import '../../../statistics/presentation/providers/statistics_provider.dart';
import '../../../../core/utils/helpers/sm2_algorithm.dart';

String _getUserId() {
  return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
}

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepository(userId: _getUserId());
});

// Family provider to get a session by ID
final sessionByIdProvider =
    FutureProvider.family<StudySessionModel?, String>((ref, sessionId) async {
  if (sessionId.isEmpty) return null;
  final repository = ref.watch(studyRepositoryProvider);
  return await repository.getSession(sessionId);
});

final sessionsProvider = FutureProvider<List<StudySessionModel>>((ref) async {
  final repository = ref.watch(studyRepositoryProvider);
  return await repository.getRecentSessions(limit: 50);
});

final todaySessionsProvider =
    FutureProvider<List<StudySessionModel>>((ref) async {
  final repository = ref.watch(studyRepositoryProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  return await repository.getSessionsInDateRange(startOfDay, endOfDay);
});

final studyStreakProvider = FutureProvider<int>((ref) async {
  // Calculate streak from sessions - simplified implementation
  final repository = ref.watch(studyRepositoryProvider);
  final sessions = await repository.getRecentSessions(limit: 100);
  if (sessions.isEmpty) return 0;

  int streak = 0;
  final DateTime currentDate = DateTime.now();

  for (int i = 0; i < 365; i++) {
    final checkDate = currentDate.subtract(Duration(days: i));
    final hasSession = sessions.any(
      (s) =>
          s.startTime.year == checkDate.year &&
          s.startTime.month == checkDate.month &&
          s.startTime.day == checkDate.day,
    );

    if (hasSession) {
      streak++;
    } else if (i > 0) {
      break;
    }
  }
  return streak;
});

// Study Session State
class StudySessionState {
  final StudySessionModel? session;
  final List<CardModel> cards;
  final int currentCardIndex;
  final bool isActive;
  final bool isComplete;
  final int cardsStudied;
  final int correctAnswers;
  final String? error;
  final DateTime? cardShownTime;

  const StudySessionState({
    this.session,
    this.cards = const [],
    this.currentCardIndex = 0,
    this.isActive = false,
    this.isComplete = false,
    this.cardsStudied = 0,
    this.correctAnswers = 0,
    this.error,
    this.cardShownTime,
  });

  CardModel? get currentCard =>
      currentCardIndex < cards.length ? cards[currentCardIndex] : null;

  bool get hasMoreCards => currentCardIndex < cards.length;

  double get progress =>
      cards.isEmpty ? 0 : (currentCardIndex / cards.length).clamp(0.0, 1.0);

  double get accuracy => cardsStudied > 0 ? correctAnswers / cardsStudied : 0;

  StudySessionState copyWith({
    StudySessionModel? session,
    List<CardModel>? cards,
    int? currentCardIndex,
    bool? isActive,
    bool? isComplete,
    int? cardsStudied,
    int? correctAnswers,
    String? error,
    DateTime? cardShownTime,
  }) {
    return StudySessionState(
      session: session ?? this.session,
      cards: cards ?? this.cards,
      currentCardIndex: currentCardIndex ?? this.currentCardIndex,
      isActive: isActive ?? this.isActive,
      isComplete: isComplete ?? this.isComplete,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      error: error,
      cardShownTime: cardShownTime ?? this.cardShownTime,
    );
  }
}

class StudySessionNotifier extends StateNotifier<StudySessionState> {
  final StudyRepository _studyRepository;
  final CardRepository _cardRepository;
  final Ref _ref;

  StudySessionNotifier(this._studyRepository, this._cardRepository, this._ref)
      : super(const StudySessionState());

  Future<void> startSession({
    required String deckId,
    required StudyMode mode,
    int? cardLimit,
    bool practiceMode = false,
    List<String>? filterTags,
    List<String>? filterCardTypes,
  }) async {
    try {
      // Get cards based on mode - practice mode gets all cards, normal mode gets due cards
      var allCards = practiceMode
          ? await _cardRepository.getCardsByDeckId(deckId)
          : await _cardRepository.getDueCards(deckId);

      // Apply tag filter if specified
      if (filterTags != null && filterTags.isNotEmpty) {
        allCards = allCards.where((card) {
          final cardTags = card.tags;
          if (cardTags.isEmpty) return false;
          return filterTags.any((tag) => cardTags.contains(tag));
        }).toList();
      }

      // Apply card type filter if specified
      if (filterCardTypes != null && filterCardTypes.isNotEmpty) {
        allCards = allCards.where((card) {
          return filterCardTypes.contains(card.type.displayName);
        }).toList();
      }

      if (allCards.isEmpty) {
        state = state.copyWith(
          error: practiceMode
              ? 'No cards match the selected filters'
              : 'No cards due for review with selected filters',
        );
        return;
      }

      // Apply limit if specified
      final cards = cardLimit != null && allCards.length > cardLimit
          ? allCards.sublist(0, cardLimit)
          : allCards;

      // Sort by priority
      final sortedCards = SM2Algorithm.sortByPriority(cards);

      // Create session
      var session = StudySessionModel.create(
        deckId: deckId,
        mode: mode,
      );
      session = session.copyWith(
        filterTags: filterTags,
        filterCardTypes: filterCardTypes,
      );
      final sessionId = await _studyRepository.createSession(session);
      session = session.copyWith(id: sessionId);

      state = StudySessionState(
        session: session,
        cards: sortedCards,
        currentCardIndex: 0,
        isActive: true,
        isComplete: false,
        cardShownTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rateCard(
    DifficultyRating rating, {
    bool usedHint = false,
  }) async {
    if (!state.isActive || state.currentCard == null) return;

    try {
      final card = state.currentCard!;

      // Validate card has valid IDs
      if (card.id.isEmpty || card.deckId.isEmpty) {
        state = state.copyWith(error: 'Invalid card: missing ID');
        return;
      }

      // Update card with SM-2 algorithm
      final updatedCard = SM2Algorithm.calculateNextReview(card, rating);
      await _cardRepository.updateCard(updatedCard);

      // Update session - apply hint penalty (0.5 instead of 1 if hint was used)
      final isCorrect = rating != DifficultyRating.again;
      // Note: scoreIncrement can be used in future for weighted scoring
      // final scoreIncrement = isCorrect ? (usedHint ? 0.5 : 1.0) : 0.0;

      var session = state.session!;
      session = session.copyWith(
        totalCards: session.totalCards + 1,
        correctCards:
            isCorrect ? session.correctCards + 1 : session.correctCards,
        incorrectCards:
            !isCorrect ? session.incorrectCards + 1 : session.incorrectCards,
        reviewedCardIds: [...session.reviewedCardIds, card.id],
      );
      await _studyRepository.updateSession(session);

      // Update state with the new session BEFORE checking isComplete
      state = state.copyWith(session: session);

      final newIndex = state.currentCardIndex + 1;
      final isComplete = newIndex >= state.cards.length;

      if (isComplete) {
        await _endSession();
      } else {
        state = state.copyWith(
          currentCardIndex: newIndex,
          cardsStudied: state.cardsStudied + 1,
          correctAnswers:
              isCorrect ? state.correctAnswers + 1 : state.correctAnswers,
          cardShownTime: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> skipCard() async {
    if (!state.isActive) return;

    final newIndex = state.currentCardIndex + 1;
    if (newIndex >= state.cards.length) {
      await _endSession();
    } else {
      state = state.copyWith(
        currentCardIndex: newIndex,
        cardShownTime: DateTime.now(),
      );
    }
  }

  Future<void> completeMatchPairsSession({
    required int cardCount,
    required int wrongAttempts,
  }) async {
    if (state.session == null) return;

    var session = state.session!;

    // In match pairs, we consider all matched cards as "studied".
    // We treat them as correct because the user eventually matched them.
    session = session.copyWith(
      totalCards: session.totalCards + cardCount,
      correctCards: session.correctCards + cardCount,
      // We could track wrongAttempts as incorrectCards if desired,
      // but usually incorrect means "failed to recall".
      // Here we just track that they finished the set.
    );

    // Update the session in DB
    await _studyRepository.updateSession(session);
    state = state.copyWith(session: session);

    // End the session properly
    await _endSession();
  }

  Future<void> _endSession() async {
    if (state.session == null) return;

    var session = state.session!;
    final endTime = DateTime.now();
    final totalTimeSeconds = endTime.difference(session.startTime).inSeconds;

    session = session.copyWith(
      status: SessionStatus.completed,
      endTime: endTime,
      totalTimeSeconds: totalTimeSeconds,
    );
    await _studyRepository.updateSession(session);

    // Update statistics
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final statsRepository = StatisticsRepository(userId: userId);
      await statsRepository.incrementStudySession(
        cardsStudied: session.totalCards,
        correctCards: session.correctCards,
        studyMinutes: (totalTimeSeconds / 60).ceil(),
      );
    } catch (e) {
      // Don't fail the session if stats update fails
      assert(() {
        // ignore: avoid_print
        print('Error updating statistics: $e');
        return true;
      }());
    }

    state = state.copyWith(
      session: session,
      isActive: false,
      isComplete: true,
      cardsStudied: state.cardsStudied + 1,
    );

    // Invalidate related providers
    _ref.invalidate(todaySessionsProvider);
    _ref.invalidate(studyStreakProvider);
    _ref.invalidate(statisticsProvider);
    _ref.invalidate(statisticsNotifierProvider);
  }

  void reset() {
    state = const StudySessionState();
  }
}

final studySessionProvider =
    StateNotifierProvider<StudySessionNotifier, StudySessionState>((ref) {
  final studyRepository = ref.watch(studyRepositoryProvider);
  final cardRepository = ref.watch(cardRepositoryProvider);
  return StudySessionNotifier(studyRepository, cardRepository, ref);
});

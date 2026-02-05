import '../../constants/study_constants.dart';
import '../../../features/cards/data/models/card_model.dart';

/// SM-2 Spaced Repetition Algorithm
///
/// Based on the SuperMemo 2 algorithm for optimal review scheduling.
class SM2Algorithm {
  /// Calculate next review data based on user rating
  ///
  /// @param card Current card state
  /// @param rating User's difficulty rating
  /// @return Updated card with new interval and next review date
  static CardModel calculateNextReview(
    CardModel card,
    DifficultyRating rating,
  ) {
    final now = DateTime.now();

    // Convert rating to numeric value
    final quality = rating.toQuality();

    // Failed review (Again button)
    if (quality < 3) {
      return card.copyWith(
        repetitions: 0,
        interval: StudyConstants.firstInterval.toDouble(),
        nextReviewDate: now.add(
          const Duration(days: StudyConstants.firstInterval),
        ),
        status: CardStatus.learning,
        timesIncorrect: card.timesIncorrect + 1,
        totalReviews: card.totalReviews + 1,
        updatedAt: now,
      );
    }

    // Successful review
    final int newRepetitions = card.repetitions + 1;
    double newInterval;

    // Calculate new interval
    if (newRepetitions == 1) {
      newInterval = StudyConstants.firstInterval.toDouble();
    } else if (newRepetitions == 2) {
      newInterval = StudyConstants.secondInterval.toDouble();
    } else {
      newInterval = card.interval * card.easeFactor;
    }

    // Calculate new ease factor
    // EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))
    double newEaseFactor =
        card.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

    // Ensure ease factor stays within bounds
    if (newEaseFactor < StudyConstants.minEaseFactor) {
      newEaseFactor = StudyConstants.minEaseFactor;
    }
    if (newEaseFactor > StudyConstants.maxEaseFactor) {
      newEaseFactor = StudyConstants.maxEaseFactor;
    }

    // Apply bonus for "Easy" rating
    if (rating == DifficultyRating.easy) {
      newInterval = newInterval * 1.3;
    }

    // Apply penalty for "Hard" rating
    if (rating == DifficultyRating.hard) {
      newInterval = newInterval * 0.8;
      if (newInterval < 1) newInterval = 1;
    }

    // Cap maximum interval at 365 days (1 year)
    if (newInterval > 365) {
      newInterval = 365;
    }

    // Determine new status
    CardStatus newStatus;
    if (newInterval < StudyConstants.learningThreshold) {
      newStatus = CardStatus.learning;
    } else if (newInterval < StudyConstants.masteredThreshold) {
      newStatus = CardStatus.review;
    } else {
      newStatus = CardStatus.mastered;
    }

    return card.copyWith(
      repetitions: newRepetitions,
      interval: newInterval,
      easeFactor: newEaseFactor,
      nextReviewDate: now.add(Duration(days: newInterval.round())),
      status: newStatus,
      timesCorrect: card.timesCorrect + 1,
      totalReviews: card.totalReviews + 1,
      updatedAt: now,
    );
  }

  /// Calculate the optimal review order for a list of cards
  ///
  /// Prioritizes:
  /// 1. Overdue cards (sorted by most overdue first)
  /// 2. Due today
  /// 3. New cards
  static List<CardModel> sortByPriority(List<CardModel> cards) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Separate cards into categories
    final overdueCards = <CardModel>[];
    final dueTodayCards = <CardModel>[];
    final newCards = <CardModel>[];
    final futureCards = <CardModel>[];

    for (final card in cards) {
      final dueDate = DateTime(
        card.nextReviewDate.year,
        card.nextReviewDate.month,
        card.nextReviewDate.day,
      );

      if (card.status == CardStatus.newCard) {
        newCards.add(card);
      } else if (dueDate.isBefore(today)) {
        overdueCards.add(card);
      } else if (dueDate.isAtSameMomentAs(today)) {
        dueTodayCards.add(card);
      } else {
        futureCards.add(card);
      }
    }

    // Sort overdue by most overdue first
    overdueCards.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));

    // Sort due today by ease factor (harder cards first)
    dueTodayCards.sort((a, b) => a.easeFactor.compareTo(b.easeFactor));

    // Combine in priority order
    return [
      ...overdueCards,
      ...dueTodayCards,
      ...newCards,
      ...futureCards,
    ];
  }

  /// Get cards that are due for review
  static List<CardModel> getDueCards(
    List<CardModel> cards, {
    int? limit,
    bool includeNew = true,
  }) {
    final now = DateTime.now();

    final dueCards = cards.where((card) {
      if (card.status == CardStatus.newCard) {
        return includeNew;
      }
      return card.nextReviewDate.isBefore(now) ||
          card.nextReviewDate.isAtSameMomentAs(now);
    }).toList();

    final sortedCards = sortByPriority(dueCards);

    if (limit != null && sortedCards.length > limit) {
      return sortedCards.sublist(0, limit);
    }

    return sortedCards;
  }

  /// Calculate estimated review time
  static Duration estimateReviewTime(List<CardModel> cards) {
    // Average 10 seconds per new card, 6 seconds per review card
    int totalSeconds = 0;
    for (final card in cards) {
      if (card.status == CardStatus.newCard) {
        totalSeconds += 10;
      } else if (card.averageResponseTime > 0) {
        totalSeconds += card.averageResponseTime.round();
      } else {
        totalSeconds += 6;
      }
    }
    return Duration(seconds: totalSeconds);
  }
}

enum DifficultyRating {
  again, // Complete blackout, wrong answer (quality = 0)
  hard, // Difficult, correct with hesitation (quality = 3)
  good, // Correct with some thought (quality = 4)
  easy, // Perfect, instant recall (quality = 5)
}

extension DifficultyRatingExtension on DifficultyRating {
  int toQuality() {
    switch (this) {
      case DifficultyRating.again:
        return 0;
      case DifficultyRating.hard:
        return 3;
      case DifficultyRating.good:
        return 4;
      case DifficultyRating.easy:
        return 5;
    }
  }

  String get displayName {
    switch (this) {
      case DifficultyRating.again:
        return 'Again';
      case DifficultyRating.hard:
        return 'Hard';
      case DifficultyRating.good:
        return 'Good';
      case DifficultyRating.easy:
        return 'Easy';
    }
  }

  String get shortcut {
    switch (this) {
      case DifficultyRating.again:
        return '1';
      case DifficultyRating.hard:
        return '2';
      case DifficultyRating.good:
        return '3';
      case DifficultyRating.easy:
        return '4';
    }
  }

  /// Get the next interval for display purposes
  String getNextInterval(CardModel card) {
    final updated = SM2Algorithm.calculateNextReview(card, this);
    final interval = updated.interval.round();

    if (interval == 0) return 'Now';
    if (interval == 1) return '1 day';
    if (interval < 7) return '$interval days';
    if (interval < 30) {
      final weeks = (interval / 7).round();
      return weeks == 1 ? '1 week' : '$weeks weeks';
    }
    if (interval < 365) {
      final months = (interval / 30).round();
      return months == 1 ? '1 month' : '$months months';
    }
    final years = (interval / 365).round();
    return years == 1 ? '1 year' : '$years years';
  }
}

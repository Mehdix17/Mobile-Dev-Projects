import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/statistics_model.dart';

class StatisticsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  StatisticsRepository({required this.userId});

  DocumentReference<Map<String, dynamic>> get _statsDocument {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('statistics');
  }

  Future<StatisticsModel> getStatistics() async {
    final doc = await _statsDocument.get();
    if (!doc.exists) {
      final initial = StatisticsModel.initial();
      await _statsDocument.set(initial.toJson());
      return initial;
    }
    return StatisticsModel.fromJson(doc.data()!, doc.id);
  }

  Future<void> updateStatistics(StatisticsModel stats) async {
    final updatedStats = stats.copyWith(lastUpdatedAt: DateTime.now());
    await _statsDocument.set(updatedStats.toJson());
  }

  Future<void> incrementStudySession({
    required int cardsStudied,
    required int correctCards,
    required int studyMinutes,
  }) async {
    final stats = await getStatistics();
    final now = DateTime.now();
    final isNewDay = !_isSameDay(stats.lastStudyDate, now);

    // Calculate new streak
    int newStreak;
    if (isNewDay) {
      if (_isYesterday(stats.lastStudyDate, now)) {
        // Continued streak from yesterday
        newStreak = stats.currentStreak + 1;
      } else if (_isSameDay(stats.lastStudyDate, now)) {
        // Same day, keep streak
        newStreak = stats.currentStreak;
      } else {
        // Streak broken, start new
        newStreak = 1;
      }
    } else {
      // Same day, keep streak
      newStreak = stats.currentStreak;
    }

    final updatedStats = stats.copyWith(
      totalStudySessions: stats.totalStudySessions + 1,
      totalStudyMinutes: stats.totalStudyMinutes + studyMinutes,
      cardsLearned:
          stats.cardsLearned + cardsStudied, // Track total cards ever studied
      cardsStudiedToday:
          isNewDay ? cardsStudied : stats.cardsStudiedToday + cardsStudied,
      studyMinutesToday:
          isNewDay ? studyMinutes : stats.studyMinutesToday + studyMinutes,
      sessionsToday: isNewDay ? 1 : stats.sessionsToday + 1,
      lastStudyDate: now,
      lastUpdatedAt: now,
      averageAccuracy: _calculateNewAverage(
        stats.averageAccuracy,
        stats.totalStudySessions,
        cardsStudied > 0 ? correctCards / cardsStudied : 0,
      ),
      currentStreak: newStreak,
      longestStreak:
          newStreak > stats.longestStreak ? newStreak : stats.longestStreak,
    );

    await updateStatistics(updatedStats);
  }

  Future<void> updateCardCounts({
    required int totalCards,
    required int cardsNew,
    required int cardsLearning,
    required int cardsMastered,
    required int cardsReview,
  }) async {
    final stats = await getStatistics();
    final updatedStats = stats.copyWith(
      totalCards: totalCards,
      cardsNew: cardsNew,
      cardsLearning: cardsLearning,
      cardsMastered: cardsMastered,
      cardsReview: cardsReview,
      lastUpdatedAt: DateTime.now(),
    );
    await updateStatistics(updatedStats);
  }

  Future<void> resetStatistics() async {
    await _statsDocument.set(StatisticsModel.initial().toJson());
  }

  Stream<StatisticsModel> watchStatistics() {
    return _statsDocument.snapshots().map((doc) {
      if (!doc.exists) return StatisticsModel.initial();
      return StatisticsModel.fromJson(doc.data()!, doc.id);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isYesterday(DateTime lastDate, DateTime now) {
    final yesterday = now.subtract(const Duration(days: 1));
    return _isSameDay(lastDate, yesterday);
  }

  double _calculateNewAverage(double oldAverage, int count, double newValue) {
    if (count == 0) return newValue;
    return (oldAverage * count + newValue) / (count + 1);
  }
}

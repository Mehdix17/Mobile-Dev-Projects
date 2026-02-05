import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsModel {
  final String id;
  final int totalCards;
  final int cardsLearned;
  final int cardsMastered;
  final int cardsLearning;
  final int cardsNew;
  final int cardsReview;
  final int totalStudySessions;
  final int totalStudyMinutes;
  final int studyMinutesToday;
  final int cardsStudiedToday;
  final int sessionsToday;
  final DateTime lastStudyDate;
  final DateTime lastUpdatedAt;
  final double averageAccuracy;
  final int currentStreak;
  final int longestStreak;
  final String dailyStudyDataJson;
  final String accuracyHistoryJson;

  StatisticsModel({
    required this.id,
    this.totalCards = 0,
    this.cardsLearned = 0,
    this.cardsMastered = 0,
    this.cardsLearning = 0,
    this.cardsNew = 0,
    this.cardsReview = 0,
    this.totalStudySessions = 0,
    this.totalStudyMinutes = 0,
    this.studyMinutesToday = 0,
    this.cardsStudiedToday = 0,
    this.sessionsToday = 0,
    required this.lastStudyDate,
    required this.lastUpdatedAt,
    this.averageAccuracy = 0.0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.dailyStudyDataJson = '{}',
    this.accuracyHistoryJson = '[]',
  });

  // Computed properties for compatibility
  int get totalCardsStudied => cardsLearned + cardsMastered + cardsLearning;
  double get overallProgress =>
      totalCards > 0 ? (cardsMastered / totalCards) * 100 : 0;

  factory StatisticsModel.initial() {
    final now = DateTime.now();
    return StatisticsModel(
      id: 'stats',
      lastStudyDate: now,
      lastUpdatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalCards': totalCards,
      'cardsLearned': cardsLearned,
      'cardsMastered': cardsMastered,
      'cardsLearning': cardsLearning,
      'cardsNew': cardsNew,
      'cardsReview': cardsReview,
      'totalStudySessions': totalStudySessions,
      'totalStudyMinutes': totalStudyMinutes,
      'studyMinutesToday': studyMinutesToday,
      'cardsStudiedToday': cardsStudiedToday,
      'sessionsToday': sessionsToday,
      'lastStudyDate': Timestamp.fromDate(lastStudyDate),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'averageAccuracy': averageAccuracy,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'dailyStudyDataJson': dailyStudyDataJson,
      'accuracyHistoryJson': accuracyHistoryJson,
    };
  }

  factory StatisticsModel.fromJson(Map<String, dynamic> json, String docId) {
    return StatisticsModel(
      id: docId,
      totalCards: json['totalCards'] as int? ?? 0,
      cardsLearned: json['cardsLearned'] as int? ?? 0,
      cardsMastered: json['cardsMastered'] as int? ?? 0,
      cardsLearning: json['cardsLearning'] as int? ?? 0,
      cardsNew: json['cardsNew'] as int? ?? 0,
      cardsReview: json['cardsReview'] as int? ?? 0,
      totalStudySessions: json['totalStudySessions'] as int? ?? 0,
      totalStudyMinutes: json['totalStudyMinutes'] as int? ?? 0,
      studyMinutesToday: json['studyMinutesToday'] as int? ?? 0,
      cardsStudiedToday: json['cardsStudiedToday'] as int? ?? 0,
      sessionsToday: json['sessionsToday'] as int? ?? 0,
      lastStudyDate:
          (json['lastStudyDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt:
          (json['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      dailyStudyDataJson: json['dailyStudyDataJson'] as String? ?? '{}',
      accuracyHistoryJson: json['accuracyHistoryJson'] as String? ?? '[]',
    );
  }

  StatisticsModel copyWith({
    String? id,
    int? totalCards,
    int? cardsLearned,
    int? cardsMastered,
    int? cardsLearning,
    int? cardsNew,
    int? cardsReview,
    int? totalStudySessions,
    int? totalStudyMinutes,
    int? studyMinutesToday,
    int? cardsStudiedToday,
    int? sessionsToday,
    DateTime? lastStudyDate,
    DateTime? lastUpdatedAt,
    double? averageAccuracy,
    int? currentStreak,
    int? longestStreak,
    String? dailyStudyDataJson,
    String? accuracyHistoryJson,
  }) {
    return StatisticsModel(
      id: id ?? this.id,
      totalCards: totalCards ?? this.totalCards,
      cardsLearned: cardsLearned ?? this.cardsLearned,
      cardsMastered: cardsMastered ?? this.cardsMastered,
      cardsLearning: cardsLearning ?? this.cardsLearning,
      cardsNew: cardsNew ?? this.cardsNew,
      cardsReview: cardsReview ?? this.cardsReview,
      totalStudySessions: totalStudySessions ?? this.totalStudySessions,
      totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
      studyMinutesToday: studyMinutesToday ?? this.studyMinutesToday,
      cardsStudiedToday: cardsStudiedToday ?? this.cardsStudiedToday,
      sessionsToday: sessionsToday ?? this.sessionsToday,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      dailyStudyDataJson: dailyStudyDataJson ?? this.dailyStudyDataJson,
      accuracyHistoryJson: accuracyHistoryJson ?? this.accuracyHistoryJson,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../study/presentation/providers/study_session_provider.dart';

/// Daily challenge configuration
class DailyChallengeConfig {
  static const int defaultDailyGoal = 15;
  static const String prefsKeyDailyGoal = 'daily_challenge_goal';
  static const String prefsKeyLastChallengeDate = 'last_challenge_date';
  static const String prefsKeyCardsCompletedToday = 'cards_completed_today';
}

/// Daily challenge state
class DailyChallengeState {
  final int dailyGoal;
  final int cardsCompletedToday;
  final bool isCompleted;
  final DateTime? lastChallengeDate;

  const DailyChallengeState({
    this.dailyGoal = DailyChallengeConfig.defaultDailyGoal,
    this.cardsCompletedToday = 0,
    this.isCompleted = false,
    this.lastChallengeDate,
  });

  double get progress =>
      dailyGoal > 0 ? (cardsCompletedToday / dailyGoal).clamp(0.0, 1.0) : 0.0;

  int get cardsRemaining =>
      (dailyGoal - cardsCompletedToday).clamp(0, dailyGoal);

  DailyChallengeState copyWith({
    int? dailyGoal,
    int? cardsCompletedToday,
    bool? isCompleted,
    DateTime? lastChallengeDate,
  }) {
    return DailyChallengeState(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      cardsCompletedToday: cardsCompletedToday ?? this.cardsCompletedToday,
      isCompleted: isCompleted ?? this.isCompleted,
      lastChallengeDate: lastChallengeDate ?? this.lastChallengeDate,
    );
  }
}

/// Daily challenge notifier
class DailyChallengeNotifier extends StateNotifier<DailyChallengeState> {
  DailyChallengeNotifier() : super(const DailyChallengeState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    final dailyGoal = prefs.getInt(DailyChallengeConfig.prefsKeyDailyGoal) ??
        DailyChallengeConfig.defaultDailyGoal;

    final lastDateStr =
        prefs.getString(DailyChallengeConfig.prefsKeyLastChallengeDate);
    DateTime? lastDate;
    if (lastDateStr != null) {
      lastDate = DateTime.tryParse(lastDateStr);
    }

    int cardsCompleted =
        prefs.getInt(DailyChallengeConfig.prefsKeyCardsCompletedToday) ?? 0;

    // Reset if it's a new day
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastDate == null ||
        lastDate.year != today.year ||
        lastDate.month != today.month ||
        lastDate.day != today.day) {
      cardsCompleted = 0;
      await _saveCardsCompleted(0);
      await _saveLastDate(today);
    }

    state = DailyChallengeState(
      dailyGoal: dailyGoal,
      cardsCompletedToday: cardsCompleted,
      isCompleted: cardsCompleted >= dailyGoal,
      lastChallengeDate: today,
    );
  }

  Future<void> addCompletedCards(int count) async {
    final newCount = state.cardsCompletedToday + count;
    final isCompleted = newCount >= state.dailyGoal;

    await _saveCardsCompleted(newCount);
    await _saveLastDate(DateTime.now());

    state = state.copyWith(
      cardsCompletedToday: newCount,
      isCompleted: isCompleted,
      lastChallengeDate: DateTime.now(),
    );
  }

  Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(DailyChallengeConfig.prefsKeyDailyGoal, goal);

    state = state.copyWith(
      dailyGoal: goal,
      isCompleted: state.cardsCompletedToday >= goal,
    );
  }

  Future<void> resetChallenge() async {
    await _saveCardsCompleted(0);
    await _saveLastDate(DateTime.now());

    state = state.copyWith(
      cardsCompletedToday: 0,
      isCompleted: false,
      lastChallengeDate: DateTime.now(),
    );
  }

  Future<void> _saveCardsCompleted(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(DailyChallengeConfig.prefsKeyCardsCompletedToday, count);
  }

  Future<void> _saveLastDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      DailyChallengeConfig.prefsKeyLastChallengeDate,
      date.toIso8601String(),
    );
  }
}

/// Daily challenge provider
final dailyChallengeProvider =
    StateNotifierProvider<DailyChallengeNotifier, DailyChallengeState>((ref) {
  return DailyChallengeNotifier();
});

/// Provider to get cards studied today from study sessions
final cardsStudiedTodayProvider = FutureProvider<int>((ref) async {
  final todaySessions = await ref.watch(todaySessionsProvider.future);

  int totalCards = 0;
  for (final session in todaySessions) {
    totalCards += session.totalCards;
  }

  return totalCards;
});

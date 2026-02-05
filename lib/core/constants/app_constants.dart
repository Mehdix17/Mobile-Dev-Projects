class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'English Flashcards';
  static const String appVersion = '1.0.0';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Card flip animation
  static const Duration cardFlipDuration = Duration(milliseconds: 400);

  // Debounce durations
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration saveDebounce = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxCardsPerSession = 100;

  // Validation
  static const int maxDeckNameLength = 50;
  static const int maxCardFieldLength = 500;
  static const int maxTagLength = 30;
  static const int maxTagsPerCard = 10;

  // Database
  static const String databaseName = 'english_flashcards';

  // Notification IDs
  static const int dailyReminderNotificationId = 1;

  // Shared preferences keys
  static const String themeModePrefKey = 'theme_mode';
  static const String dailyNewCardLimitPrefKey = 'daily_new_card_limit';
  static const String dailyReviewLimitPrefKey = 'daily_review_limit';
  static const String notificationsEnabledPrefKey = 'notifications_enabled';
  static const String reminderTimePrefKey = 'reminder_time';
  static const String lastStudyDatePrefKey = 'last_study_date';
  static const String currentStreakPrefKey = 'current_streak';
}

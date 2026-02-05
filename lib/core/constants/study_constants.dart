class StudyConstants {
  StudyConstants._();

  // SM-2 Algorithm parameters
  static const double minEaseFactor = 1.3;
  static const double initialEaseFactor = 2.5;
  static const double maxEaseFactor = 3.0;

  // Initial intervals (in days)
  static const int firstInterval = 1;
  static const int secondInterval = 6;

  // Card status thresholds (in days)
  static const int learningThreshold = 21;
  static const int masteredThreshold = 90;

  // Default limits
  static const int defaultDailyNewCards = 20;
  static const int defaultDailyReviewCards = 100;

  // Speed round settings
  static const int speedRoundTimePerCard = 15; // seconds
  static const int speedRoundBaseScore = 100;
  static const double speedRoundMultiplierIncrease = 0.1;
  static const double speedRoundMaxMultiplier = 3.0;

  // Match pairs settings
  static const int matchPairsMinCards = 4;
  static const int matchPairsMaxCards = 12;
  static const int matchPairsDefaultCards = 8;

  // Multiple choice settings
  static const int multipleChoiceOptions = 4;

  // Daily challenge settings
  static const int dailyChallengeCardCount = 15;
  static const int dailyChallengeNewCardPercent = 20;

  // Fuzzy matching threshold (0-100)
  static const int fuzzyMatchThreshold = 80;

  // Study session limits
  static const int maxSessionDurationMinutes = 60;
  static const int sessionWarningMinutes = 45;
}

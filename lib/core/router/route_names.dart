class RouteNames {
  RouteNames._();

  // Bottom navigation
  static const String home = '/';
  static const String decks = '/decks';
  static const String marketplace = '/marketplace';
  static const String settings = '/settings';

  // Deck routes
  static const String deckDetail = '/deck';
  static const String deckEditor = '/deck/editor';

  // Card routes
  static const String cardDetail = '/card';
  static const String cardEditor = '/card/editor';

  // Study routes
  static const String studyModeSelector = '/study';
  static const String flipCard = '/study/flip';
  static const String multipleChoice = '/study/multiple-choice';
  static const String matchPairs = '/study/match-pairs';
  static const String studySummary = '/study/summary';

  // Statistics route (accessible from home screen)
  static const String statistics = '/statistics';

  // Auth routes
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';

  // Import/Export routes
  static const String import = '/import';
  static const String export = '/export';
}

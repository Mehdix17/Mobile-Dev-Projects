import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/decks/presentation/screens/deck_list_screen.dart';
import '../../features/decks/presentation/screens/deck_detail_screen.dart';
import '../../features/decks/presentation/screens/deck_editor_screen.dart';
import '../../features/cards/presentation/screens/card_editor_screen.dart';
import '../../features/cards/presentation/screens/card_detail_screen.dart';
import '../../features/study/presentation/screens/study_mode_selector_screen.dart';
import '../../features/study/presentation/screens/flip_card_screen.dart';
import '../../features/study/presentation/screens/multiple_choice_screen.dart';
import '../../features/study/presentation/screens/match_pairs_screen.dart';
import '../../features/study/presentation/screens/study_summary_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/import_export/presentation/screens/import_screen.dart';
import '../../features/import_export/presentation/screens/export_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.home,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: RouteNames.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.decks,
            name: RouteNames.decks,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DeckListScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.marketplace,
            name: RouteNames.marketplace,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MarketplaceScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.settings,
            name: RouteNames.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      // Deck routes - deckEditor must come BEFORE deckDetail to avoid matching /deck/editor as /deck/:deckId
      GoRoute(
        path: RouteNames.deckEditor,
        name: RouteNames.deckEditor,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => DeckEditorScreen(
          deckId: state.uri.queryParameters['deckId'],
        ),
      ),
      GoRoute(
        path: '${RouteNames.deckDetail}/:deckId',
        name: RouteNames.deckDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => DeckDetailScreen(
          deckId: state.pathParameters['deckId']!,
        ),
      ),
      // Card routes
      GoRoute(
        path: RouteNames.cardDetail,
        name: RouteNames.cardDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CardDetailScreen(
          cardId: state.uri.queryParameters['cardId']!,
          deckId: state.uri.queryParameters['deckId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.cardEditor,
        name: RouteNames.cardEditor,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CardEditorScreen(
          deckId: state.uri.queryParameters['deckId']!,
          cardId: state.uri.queryParameters['cardId'],
        ),
      ),
      // Study routes
      // Note: studySummary must come BEFORE studyModeSelector to prevent
      // /study/summary being matched as /study/:deckId with deckId="summary"
      GoRoute(
        path: RouteNames.studySummary,
        name: RouteNames.studySummary,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'] ?? '';
          return StudySummaryScreen(
            sessionId: sessionId,
          );
        },
      ),
      GoRoute(
        path: '${RouteNames.studyModeSelector}/:deckId',
        name: RouteNames.studyModeSelector,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StudyModeSelectorScreen(
          deckId: state.pathParameters['deckId']!,
        ),
      ),
      GoRoute(
        path: '${RouteNames.flipCard}/:deckId',
        name: RouteNames.flipCard,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final totalCards = state.uri.queryParameters['totalCards'];
          final tagsParam = state.uri.queryParameters['tags'];
          final cardTypesParam = state.uri.queryParameters['cardTypes'];
          return FlipCardScreen(
            deckId: state.pathParameters['deckId']!,
            practiceMode: state.uri.queryParameters['practice'] == 'true',
            cardLimit: totalCards != null ? int.tryParse(totalCards) : null,
            filterTags:
                tagsParam?.isNotEmpty == true ? tagsParam!.split(',') : null,
            filterCardTypes: cardTypesParam?.isNotEmpty == true
                ? cardTypesParam!.split(',')
                : null,
          );
        },
      ),
      GoRoute(
        path: '${RouteNames.multipleChoice}/:deckId',
        name: RouteNames.multipleChoice,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final totalCards = state.uri.queryParameters['totalCards'];
          final tagsParam = state.uri.queryParameters['tags'];
          final cardTypesParam = state.uri.queryParameters['cardTypes'];
          return MultipleChoiceScreen(
            deckId: state.pathParameters['deckId']!,
            practiceMode: state.uri.queryParameters['practice'] == 'true',
            cardLimit: totalCards != null ? int.tryParse(totalCards) : null,
            filterTags:
                tagsParam?.isNotEmpty == true ? tagsParam!.split(',') : null,
            filterCardTypes: cardTypesParam?.isNotEmpty == true
                ? cardTypesParam!.split(',')
                : null,
          );
        },
      ),
      GoRoute(
        path: '${RouteNames.matchPairs}/:deckId',
        name: RouteNames.matchPairs,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final totalCards = state.uri.queryParameters['totalCards'];
          final tagsParam = state.uri.queryParameters['tags'];
          final cardTypesParam = state.uri.queryParameters['cardTypes'];
          return MatchPairsScreen(
            deckId: state.pathParameters['deckId']!,
            practiceMode: state.uri.queryParameters['practice'] == 'true',
            cardLimit: totalCards != null ? int.tryParse(totalCards) : null,
            filterTags:
                tagsParam?.isNotEmpty == true ? tagsParam!.split(',') : null,
            filterCardTypes: cardTypesParam?.isNotEmpty == true
                ? cardTypesParam!.split(',')
                : null,
          );
        },
      ),
      // Import/Export routes
      GoRoute(
        path: RouteNames.import,
        name: RouteNames.import,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ImportScreen(),
      ),
      GoRoute(
        path: RouteNames.export,
        name: RouteNames.export,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ExportScreen(
          deckId: state.uri.queryParameters['deckId'],
        ),
      ),
      // Statistics route (accessible from home screen, not in bottom nav)
      GoRoute(
        path: RouteNames.statistics,
        name: RouteNames.statistics,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StatisticsScreen(),
      ),
      // Auth routes
      GoRoute(
        path: RouteNames.signIn,
        name: RouteNames.signIn,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RouteNames.signUp,
        name: RouteNames.signUp,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: RouteNames.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
    ],
  );
});

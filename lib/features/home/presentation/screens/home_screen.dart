import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/services/predefined_decks_service.dart';
import '../../../decks/presentation/providers/deck_provider.dart';
import '../../../study/presentation/providers/study_session_provider.dart';
import '../../../statistics/presentation/providers/statistics_provider.dart';
import '../widgets/quick_stats_card.dart';
import '../widgets/recent_decks_list.dart';
import '../widgets/daily_challenge_card.dart';

// Provider to initialize predefined decks for new users
final _predefinedDecksInitProvider = FutureProvider<bool>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  final service = PredefinedDecksService(userId: userId);

  // Check if decks were created
  final hadDecks = await service.hasExistingDecks();
  if (!hadDecks) {
    await service.createPredefinedDecks();
    // Return true to indicate decks were created
    return true;
  }
  return false;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    return shouldExit == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(statisticsNotifierProvider);
    final recentDecksAsync = ref.watch(recentDecksProvider);
    final streakAsync = ref.watch(studyStreakProvider);

    // Initialize predefined decks for new users (runs once)
    final predefinedDecksAsync = ref.watch(_predefinedDecksInitProvider);

    // If predefined decks were just created, refresh the providers
    predefinedDecksAsync.whenData((created) {
      if (created) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(decksProvider);
          ref.invalidate(recentDecksProvider);
          ref.invalidate(deckListProvider);
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await _showExitConfirmation(context);
          if (shouldExit) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cardly'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Search functionality will be added in future updates
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(statisticsNotifierProvider);
            ref.invalidate(recentDecksProvider);
            ref.invalidate(studyStreakProvider);
            ref.invalidate(decksProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting and streak
                _buildGreeting(context, streakAsync),
                const SizedBox(height: 24),

                // Quick stats
                statsAsync.when(
                  data: (stats) => QuickStatsCard(stats: stats),
                  loading: () => const SizedBox(
                    height: 120,
                    child: LoadingIndicator(),
                  ),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),

                // Daily challenge
                const DailyChallengeCard(),
                const SizedBox(height: 24),

                // Recent decks
                Text(
                  'Recent Decks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                recentDecksAsync.when(
                  data: (decks) => decks.isEmpty
                      ? _buildEmptyRecentDecks(context)
                      : RecentDecksList(decks: decks),
                  loading: () => const SizedBox(
                    height: 100,
                    child: LoadingIndicator(),
                  ),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, AsyncValue<int> streakAsync) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning!';
    } else if (hour < 18) {
      greeting = 'Good Afternoon!';
    } else {
      greeting = 'Good Evening!';
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to learn something new?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        streakAsync.when(
          data: (streak) => streak > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildEmptyRecentDecks(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('📚', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'No recent activity',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Start studying to see your recent decks here',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

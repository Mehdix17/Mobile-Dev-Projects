import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../decks/presentation/providers/deck_provider.dart';
import '../providers/daily_challenge_provider.dart';

class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final challengeState = ref.watch(dailyChallengeProvider);
    final cardsStudiedAsync = ref.watch(cardsStudiedTodayProvider);

    // Sync studied cards with challenge state
    cardsStudiedAsync.whenData((cardsStudied) {
      if (cardsStudied > challengeState.cardsCompletedToday) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(dailyChallengeProvider.notifier).addCompletedCards(
                cardsStudied - challengeState.cardsCompletedToday,
              );
        });
      }
    });

    final progress = challengeState.progress;
    final completed = challengeState.cardsCompletedToday;
    final goal = challengeState.dailyGoal;
    final isCompleted = challengeState.isCompleted;

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCompleted
                ? [
                    Colors.green.shade400,
                    Colors.green.shade600,
                  ]
                : [
                    AppColors.secondary.withValues(alpha: 0.8),
                    AppColors.secondary,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isCompleted ? '🎉' : '🏆',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCompleted
                              ? 'Challenge Complete!'
                              : 'Daily Challenge',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCompleted
                          ? 'Great job! You\'ve completed today\'s challenge!'
                          : 'Complete $goal cards to maintain your streak!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Progress indicator
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$completed/$goal',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!isCompleted)
                ElevatedButton(
                  onPressed: () => _startChallenge(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Start'),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChallenge(BuildContext context, WidgetRef ref) async {
    // Get available decks and start studying the first one with cards
    final decksAsync = ref.read(decksProvider);

    decksAsync.whenData((decks) {
      if (decks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create a deck first to start the challenge!'),
          ),
        );
        return;
      }

      // Find a deck with cards
      final deckWithCards = decks.firstWhere(
        (d) => d.cardCount > 0,
        orElse: () => decks.first,
      );

      if (deckWithCards.cardCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add some cards to your decks first!')),
        );
        return;
      }

      // Navigate to study mode selector
      context.push('${RouteNames.studyModeSelector}/${deckWithCards.id}');
    });
  }
}

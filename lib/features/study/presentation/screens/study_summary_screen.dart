import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/models/study_session_model.dart';
import '../providers/study_session_provider.dart';

class StudySummaryScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const StudySummaryScreen({super.key, required this.sessionId});

  @override
  ConsumerState<StudySummaryScreen> createState() => _StudySummaryScreenState();
}

class _StudySummaryScreenState extends ConsumerState<StudySummaryScreen> {
  void _handleBackNavigation(BuildContext context, String deckId) {
    // Reset the study session provider before navigating
    ref.invalidate(studySessionProvider);
    ref.read(studySessionProvider.notifier).reset();
    // Pop back to previous screen (study mode selector)
    context.pop();
  }

  void _navigateToDecks(BuildContext context) {
    // Reset the study session provider before navigating
    ref.invalidate(studySessionProvider);
    ref.read(studySessionProvider.notifier).reset();
    context.go(RouteNames.decks);
  }

  void _navigateToHome(BuildContext context) {
    // Reset the study session provider before navigating
    ref.invalidate(studySessionProvider);
    ref.read(studySessionProvider.notifier).reset();
    context.go(RouteNames.home);
  }

  void _navigateToGameSettings(BuildContext context, String deckId) {
    // Reset the study session provider before navigating
    ref.invalidate(studySessionProvider);
    ref.read(studySessionProvider.notifier).reset();
    // Navigate to decks first, then push game settings so back button works properly
    context.go(RouteNames.decks);
    context.push('${RouteNames.studyModeSelector}/$deckId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionAsync = ref.watch(sessionByIdProvider(widget.sessionId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Session not found')),
          );
        }

        final accuracy = session.cardsStudied > 0
            ? session.cardsCorrect / session.cardsStudied
            : 0.0;
        final isGoodPerformance = accuracy >= 0.7;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackNavigation(context, session.deckId);
          },
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Celebration or encouragement icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: (isGoodPerformance
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          isGoodPerformance ? '🎉' : '💪',
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      isGoodPerformance ? 'Great Job!' : 'Keep Practicing!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Session completed',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Stats grid
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.library_books,
                                  label: 'Cards Studied',
                                  value: session.cardsStudied.toString(),
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.check_circle,
                                  label: 'Correct',
                                  value: session.cardsCorrect.toString(),
                                  valueColor: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.percent,
                                  label: 'Accuracy',
                                  value:
                                      '${(accuracy * 100).toStringAsFixed(0)}%',
                                  valueColor: isGoodPerformance
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.timer,
                                  label: 'Duration',
                                  value: session.duration.toMinuteString(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    _buildActionButtons(context, session),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic session) {
    final deckId = session.deckId as String;
    final currentMode = session.mode as StudyMode?;
    final cardCount = session.totalCards as int;
    final filterTags = session.filterTags as List<String>?;
    final filterCardTypes = session.filterCardTypes as List<String>?;

    return Column(
      children: [
        // Primary action - Play Again
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _replayGame(
              context,
              deckId,
              currentMode,
              cardCount,
              filterTags,
              filterCardTypes,
            ),
            icon: const Icon(Icons.replay),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            label: const Text('Play Again'),
          ),
        ),
        const SizedBox(height: 12),

        // Game Settings
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToGameSettings(context, deckId),
            icon: const Icon(Icons.settings),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            label: const Text('Game Settings'),
          ),
        ),
        const SizedBox(height: 12),

        // All Decks button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToDecks(context),
            icon: const Icon(Icons.library_books, size: 20),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(14),
            ),
            label: const Text('All Decks'),
          ),
        ),
        const SizedBox(height: 12),

        // Home button
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => _navigateToHome(context),
            icon: const Icon(Icons.home),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            label: const Text('Back to Home'),
          ),
        ),
      ],
    );
  }

  void _replayGame(
    BuildContext context,
    String deckId,
    StudyMode? mode,
    int cardCount,
    List<String>? filterTags,
    List<String>? filterCardTypes,
  ) {
    // Invalidate providers to force fresh state
    ref.invalidate(sessionByIdProvider(widget.sessionId));
    ref.invalidate(studySessionProvider);

    // Reset the study session notifier
    ref.read(studySessionProvider.notifier).reset();

    if (mode == null) {
      context.go('${RouteNames.studyModeSelector}/$deckId');
      return;
    }

    // Build path with practice=true and totalCards to ensure replay works
    final basePath = switch (mode) {
      StudyMode.flipCard => '${RouteNames.flipCard}/$deckId',
      StudyMode.multipleChoice => '${RouteNames.multipleChoice}/$deckId',
      StudyMode.matchPairs => '${RouteNames.matchPairs}/$deckId',
    };

    // Build query params including filters
    final queryParams = <String>['practice=true', 'totalCards=$cardCount'];
    if (filterTags != null && filterTags.isNotEmpty) {
      queryParams.add('tags=${Uri.encodeComponent(filterTags.join(','))}');
    }
    if (filterCardTypes != null && filterCardTypes.isNotEmpty) {
      queryParams
          .add('cardTypes=${Uri.encodeComponent(filterCardTypes.join(','))}');
    }

    context.go('$basePath?${queryParams.join('&')}');
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

extension on Duration {
  String toMinuteString() {
    final minutes = inMinutes;
    final seconds = inSeconds % 60;
    if (minutes == 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }
}

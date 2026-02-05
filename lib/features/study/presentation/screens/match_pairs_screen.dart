import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../cards/data/models/card_model.dart';
import '../../data/models/study_session_model.dart';
import '../providers/study_session_provider.dart';
import '../widgets/progress_indicator.dart';

class MatchPairsScreen extends ConsumerStatefulWidget {
  final String deckId;
  final bool practiceMode;
  final int? cardLimit;
  final List<String>? filterTags;
  final List<String>? filterCardTypes;

  const MatchPairsScreen({
    super.key,
    required this.deckId,
    this.practiceMode = false,
    this.cardLimit,
    this.filterTags,
    this.filterCardTypes,
  });

  @override
  ConsumerState<MatchPairsScreen> createState() => _MatchPairsScreenState();
}

class _MatchPairsScreenState extends ConsumerState<MatchPairsScreen> {
  List<_MatchItem> _items = [];
  _MatchItem? _selectedItem;
  final Set<int> _matchedPairs = {};
  int _correctMatches = 0;
  int _wrongAttempts = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studySessionProvider.notifier).startSession(
            deckId: widget.deckId,
            mode: StudyMode.matchPairs,
            practiceMode: widget.practiceMode,
            cardLimit: widget.cardLimit,
            filterTags: widget.filterTags,
            filterCardTypes: widget.filterCardTypes,
          );
    });
  }

  void _generateMatchItems() {
    final sessionState = ref.read(studySessionProvider);
    // Filter out image cards (wordImage type or cards with image paths)
    final textOnlyCards = sessionState.cards.where((card) {
      final isImageType = card.type.toString().contains('wordImage');
      final frontIsImage =
          card.front.startsWith('/') || card.front.contains('/');
      final backIsImage = card.back.startsWith('/') || card.back.contains('/');
      return !isImageType && !frontIsImage && !backIsImage;
    }).toList();
    final cards = textOnlyCards.take(4).toList(); // Use 4 cards for matching

    if (cards.isEmpty) return;

    _items = [];
    for (int i = 0; i < cards.length; i++) {
      _items.add(
        _MatchItem(
          id: i * 2,
          pairId: i,
          text: cards[i].front,
          isQuestion: true,
          card: cards[i],
        ),
      );
      _items.add(
        _MatchItem(
          id: i * 2 + 1,
          pairId: i,
          text: cards[i].back,
          isQuestion: false,
          card: cards[i],
        ),
      );
    }
    _items.shuffle();
  }

  void _selectItem(_MatchItem item) {
    if (_matchedPairs.contains(item.pairId)) return;

    HapticFeedback.lightImpact();

    if (_selectedItem == null) {
      setState(() => _selectedItem = item);
    } else if (_selectedItem!.id == item.id) {
      setState(() => _selectedItem = null);
    } else if (_selectedItem!.pairId == item.pairId &&
        _selectedItem!.isQuestion != item.isQuestion) {
      // Correct match
      HapticFeedback.mediumImpact();
      setState(() {
        _matchedPairs.add(item.pairId);
        _correctMatches++;
        _selectedItem = null;
      });

      if (_matchedPairs.length == 4) {
        _completeRound();
      }
    } else {
      // Wrong match
      setState(() {
        _wrongAttempts++;
        _selectedItem = null;
      });
    }
  }

  void _completeRound() {
    setState(() => _isComplete = true);

    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (mounted) {
        // Log the session completion stats
        await ref.read(studySessionProvider.notifier).completeMatchPairsSession(
              cardCount: _matchedPairs.length,
              wrongAttempts: _wrongAttempts,
            );

        if (mounted) {
          final sessionId = ref.read(studySessionProvider).session?.id ?? '';
          context.go(
            '${RouteNames.studySummary}?sessionId=$sessionId',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionState = ref.watch(studySessionProvider);

    if (sessionState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Pairs')),
        body: Center(child: Text(sessionState.error!)),
      );
    }

    if (!sessionState.isActive || sessionState.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Pairs')),
        body: const LoadingIndicator(message: 'Loading cards...'),
      );
    }

    if (_items.isEmpty) {
      _generateMatchItems();
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match the Pairs'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_matchedPairs.length}/4',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            StudyProgressIndicator(progress: _matchedPairs.length / 4),
            const SizedBox(height: 16),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(
                    icon: Icons.check_circle,
                    label: 'Matched',
                    value: '$_correctMatches',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 16),
                  _StatChip(
                    icon: Icons.cancel,
                    label: 'Wrong',
                    value: '$_wrongAttempts',
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Match grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isMatched = _matchedPairs.contains(item.pairId);
                    final isSelected = _selectedItem?.id == item.id;

                    return _MatchCard(
                      item: item,
                      isMatched: isMatched,
                      isSelected: isSelected,
                      onTap: () => _selectItem(item),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Complete message
            if (_isComplete)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.celebration, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'All matched! Great job!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MatchItem {
  final int id;
  final int pairId;
  final String text;
  final bool isQuestion;
  final CardModel card;

  _MatchItem({
    required this.id,
    required this.pairId,
    required this.text,
    required this.isQuestion,
    required this.card,
  });
}

class _MatchCard extends StatelessWidget {
  final _MatchItem item;
  final bool isMatched;
  final bool isSelected;
  final VoidCallback onTap;

  const _MatchCard({
    required this.item,
    required this.isMatched,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    Color borderColor;

    if (isMatched) {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      borderColor = AppColors.success;
    } else if (isSelected) {
      bgColor = theme.colorScheme.primaryContainer;
      borderColor = theme.colorScheme.primary;
    } else {
      bgColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
    }

    return InkWell(
      onTap: isMatched ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isMatched)
              const Icon(Icons.check_circle, color: AppColors.success)
            else
              Text(
                item.text.isEmpty
                    ? ''
                    : item.text[0].toUpperCase() + item.text.substring(1),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.isQuestion
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.isQuestion ? 'Q' : 'A',
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      item.isQuestion ? AppColors.primary : AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum DifficultyRating { again, hard, good, easy }

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/helpers/sm2_algorithm.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../cards/data/models/card_model_firestore.dart';
import '../../data/models/study_session_model.dart';
import '../providers/study_session_provider.dart';
import '../widgets/progress_indicator.dart';
import '../../../decks/presentation/providers/deck_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class MultipleChoiceScreen extends ConsumerStatefulWidget {
  final String deckId;
  final bool practiceMode;
  final int? cardLimit;
  final List<String>? filterTags;
  final List<String>? filterCardTypes;

  const MultipleChoiceScreen({
    super.key,
    required this.deckId,
    this.practiceMode = false,
    this.cardLimit,
    this.filterTags,
    this.filterCardTypes,
  });

  @override
  ConsumerState<MultipleChoiceScreen> createState() =>
      _MultipleChoiceScreenState();
}

class _MultipleChoiceScreenState extends ConsumerState<MultipleChoiceScreen> {
  int? _selectedIndex;
  bool _showResult = false;
  List<String> _options = [];
  int _correctIndex = 0;
  String? _lastCardId;
  bool _hasNavigatedToSummary = false;
  bool _isCardReversed = false;

  @override
  void initState() {
    super.initState();
    _isCardReversed = _determineCardOrientation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studySessionProvider.notifier).startSession(
            deckId: widget.deckId,
            mode: StudyMode.multipleChoice,
            practiceMode: widget.practiceMode,
            cardLimit: widget.cardLimit,
            filterTags: widget.filterTags,
            filterCardTypes: widget.filterCardTypes,
          );
    });
  }

  bool _determineCardOrientation() {
    final settings = ref.read(settingsProvider);
    final mode = settings.cardDirectionMode;

    switch (mode) {
      case 'frontFirst':
        return false; // Show front as question
      case 'backFirst':
        return true; // Show back as question
      case 'shuffle':
      default:
        return math.Random().nextBool(); // Random
    }
  }

  void _generateOptions() {
    final sessionState = ref.read(studySessionProvider);
    final currentCard = sessionState.currentCard;
    if (currentCard == null) return;

    // Mark this card ID as having options generated
    _lastCardId = currentCard.id;

    final allCards = sessionState.cards;

    // Helper to check if content is an image path
    bool isImagePath(String content) {
      return content.isNotEmpty &&
          (content.startsWith('/') || content.contains('/data/'));
    }

    // For Image card type, always use back (text) as answer, never the image
    String getTextAnswer(dynamic card) {
      if (card.type == CardType.wordImage) {
        return card.back; // Always use text for Image cards
      }
      return _isCardReversed ? card.front : card.back;
    }

    // Swap question/answer based on card direction
    final correctAnswer = getTextAnswer(currentCard);

    // Get wrong answers from other cards (only text, never image paths)
    final wrongAnswers = allCards
        .where((c) => c.id != currentCard.id)
        .map((c) => getTextAnswer(c))
        .where((answer) => !isImagePath(answer)) // Filter out any image paths
        .toSet()
        .take(3)
        .toList();

    // If not enough wrong answers, generate placeholders
    while (wrongAnswers.length < 3) {
      wrongAnswers.add('Option ${wrongAnswers.length + 1}');
    }

    // Combine and shuffle
    _options = [correctAnswer, ...wrongAnswers]..shuffle();
    _correctIndex = _options.indexOf(correctAnswer);
  }

  void _selectOption(int index) {
    if (_showResult) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
      _showResult = true;
    });

    // Rate card based on answer
    final isCorrect = index == _correctIndex;
    final rating = isCorrect ? DifficultyRating.good : DifficultyRating.again;

    // Delay before moving to next card
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        ref.read(studySessionProvider.notifier).rateCard(rating);
        // Reset state for next card
        setState(() {
          _selectedIndex = null;
          _showResult = false;
          _options = [];
          _lastCardId = null; // Clear so options regenerate for next card
          _isCardReversed = _determineCardOrientation();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionState = ref.watch(studySessionProvider);

    // Handle session completion
    if (sessionState.isComplete &&
        sessionState.session != null &&
        !_hasNavigatedToSummary) {
      _hasNavigatedToSummary = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(
            '${RouteNames.studySummary}?sessionId=${sessionState.session!.id}',
          );
        }
      });
    }

    if (sessionState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Multiple Choice')),
        body: Center(child: Text(sessionState.error!)),
      );
    }

    if (!sessionState.isActive || sessionState.currentCard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Multiple Choice')),
        body: const LoadingIndicator(message: 'Loading cards...'),
      );
    }

    final card = sessionState.currentCard!;

    // Generate options for new card (only if card changed or options empty)
    if (_options.isEmpty || _lastCardId != card.id) {
      _generateOptions();
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${sessionState.currentCardIndex + 1}/${sessionState.cards.length}',
          ),
        ),
        body: Column(
          children: [
            StudyProgressIndicator(progress: sessionState.progress),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Question card
                    Builder(
                      builder: (context) {
                        // For Image cards, always show image as question
                        final questionContent = card.type == CardType.wordImage
                            ? card.front // Always show image for Image cards
                            : (_isCardReversed ? card.back : card.front);
                        final isImage = questionContent.isNotEmpty &&
                            (questionContent.startsWith('/') ||
                                questionContent.contains('/'));

                        return Expanded(
                          flex: isImage ? 3 : 2,
                          child: Container(
                            width: double.infinity,
                            padding: isImage
                                ? const EdgeInsets.all(8)
                                : const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isImage
                                  ? theme.colorScheme.surface
                                  : theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: isImage
                                  ? Border.all(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.2),
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: isImage
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow
                                            .withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Check if question is an image path
                                Builder(
                                  builder: (context) {
                                    // For Image cards, always show image as question
                                    final questionContent =
                                        card.type == CardType.wordImage
                                            ? card.front
                                            : (_isCardReversed
                                                ? card.back
                                                : card.front);
                                    final isImage =
                                        questionContent.isNotEmpty &&
                                            (questionContent.startsWith('/') ||
                                                questionContent.contains('/'));

                                    // Only show emoji if not an image and not an Image card type
                                    if (!isImage &&
                                        card.type != CardType.wordImage) {
                                      final deckAsync = ref
                                          .watch(deckProvider(widget.deckId));
                                      final deckEmoji = _isCardReversed
                                          ? deckAsync.value?.backEmoji
                                          : deckAsync.value?.frontEmoji;
                                      if (deckEmoji != null &&
                                          deckEmoji.isNotEmpty) {
                                        return Column(
                                          children: [
                                            Text(
                                              deckEmoji,
                                              style:
                                                  const TextStyle(fontSize: 48),
                                            ),
                                            const SizedBox(height: 24),
                                          ],
                                        );
                                      }
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                // Display question content (image or text)
                                Builder(
                                  builder: (context) {
                                    // For Image cards, always show image as question
                                    final content =
                                        card.type == CardType.wordImage
                                            ? card.front
                                            : (_isCardReversed
                                                ? card.back
                                                : card.front);
                                    final isImageContent = content.isNotEmpty &&
                                        (content.startsWith('/') ||
                                            content.contains('/'));

                                    if (isImageContent) {
                                      return Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.file(
                                            File(content),
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Text(
                                                _capitalize(content),
                                                style: theme
                                                    .textTheme.headlineSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                                textAlign: TextAlign.center,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    } else {
                                      return Text(
                                        _capitalize(content),
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                        textAlign: TextAlign.center,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Options
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: Column(
                          children: List.generate(_options.length, (index) {
                            final isSelected = _selectedIndex == index;
                            final isCorrect = index == _correctIndex;

                            Color? backgroundColor;
                            Color? borderColor;

                            if (_showResult) {
                              if (isCorrect) {
                                backgroundColor =
                                    AppColors.success.withValues(alpha: 0.1);
                                borderColor = AppColors.success;
                              } else if (isSelected && !isCorrect) {
                                backgroundColor =
                                    AppColors.error.withValues(alpha: 0.1);
                                borderColor = AppColors.error;
                              }
                            } else if (isSelected) {
                              backgroundColor =
                                  theme.colorScheme.primaryContainer;
                              borderColor = theme.colorScheme.primary;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => _selectOption(index),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: backgroundColor ??
                                        theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: borderColor ??
                                          theme.colorScheme.outline
                                              .withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: (borderColor ??
                                                      theme.colorScheme.primary)
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme
                                              .surfaceContainerHighest,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(
                                              65 + index,
                                            ), // A, B, C, D
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _capitalize(_options[index]),
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                      if (_showResult && isCorrect)
                                        const Icon(
                                          Icons.check_circle,
                                          color: AppColors.success,
                                        )
                                      else if (_showResult &&
                                          isSelected &&
                                          !isCorrect)
                                        const Icon(
                                          Icons.cancel,
                                          color: AppColors.error,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

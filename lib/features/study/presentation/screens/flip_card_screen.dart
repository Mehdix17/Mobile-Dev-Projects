import 'dart:io';
import 'dart:math' as math;
import 'package:cardly/features/study/data/models/study_session_model.dart';
import 'package:cardly/features/cards/data/models/card_model_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/helpers/sm2_algorithm.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/study_session_provider.dart';
import '../widgets/difficulty_buttons.dart';
import '../widgets/progress_indicator.dart';
import '../../../decks/presentation/providers/deck_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class FlipCardScreen extends ConsumerStatefulWidget {
  final String deckId;
  final bool practiceMode;
  final int? cardLimit;
  final List<String>? filterTags;
  final List<String>? filterCardTypes;

  const FlipCardScreen({
    super.key,
    required this.deckId,
    this.practiceMode = false,
    this.cardLimit,
    this.filterTags,
    this.filterCardTypes,
  });

  @override
  ConsumerState<FlipCardScreen> createState() => _FlipCardScreenState();
}

class _FlipCardScreenState extends ConsumerState<FlipCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showingFront = true;
  bool _isFlipping = false;
  bool _hasNavigatedToSummary = false;
  int _currentFace = 1; // For 3-face cards: 1, 2, or 3
  int _nextFace = 1; // Track the next face during animation
  bool _goingForward = true; // Direction for 3-face cards
  bool _usedHint = false; // Track if hint was used for current card
  bool _isCardReversed =
      false; // Track if current card is reversed (back first)

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    // Start the study session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isCardReversed = _determineCardOrientation();
      ref.read(studySessionProvider.notifier).startSession(
            deckId: widget.deckId,
            mode: StudyMode.flipCard,
            practiceMode: widget.practiceMode,
            cardLimit: widget.cardLimit,
            filterTags: widget.filterTags,
            filterCardTypes: widget.filterCardTypes,
          );
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipping) return;

    final sessionState = ref.read(studySessionProvider);
    final card = sessionState.currentCard;

    // Handle 3-face cards differently
    if (card != null && card.isThreeFaces) {
      _flipThreeFaceCard();
      return;
    }

    _isFlipping = true;

    if (_showingFront) {
      _flipController.forward().then((_) {
        setState(() {
          _showingFront = false;
          _isFlipping = false;
        });
      });
    } else {
      _flipController.reverse().then((_) {
        setState(() {
          _showingFront = true;
          _isFlipping = false;
        });
      });
    }
  }

  void _flipThreeFaceCard() {
    _isFlipping = true;

    // Determine next face based on direction
    if (_goingForward) {
      _nextFace = _currentFace + 1;
    } else {
      _nextFace = _currentFace - 1;
    }

    _flipController.forward().then((_) {
      setState(() {
        _currentFace = _nextFace;
        // Reverse direction at boundaries
        if (_currentFace >= 3) {
          _goingForward = false;
        } else if (_currentFace <= 1) {
          _goingForward = true;
        }
        _isFlipping = false;
      });
      _flipController.reset();
    });
  }

  void _showHint() {
    final sessionState = ref.read(studySessionProvider);
    final card = sessionState.currentCard;
    if (card == null) return;

    // Get hint for the question side (what's shown first)
    // If card is reversed, the "question" is the back, so use backHint
    String? hint = _isCardReversed ? card.backHint : card.frontHint;

    // Fallback: check in fields map for backward compatibility (old cards stored hints there)
    if (hint == null || hint.isEmpty) {
      final fieldKey = _isCardReversed ? 'backHint' : 'frontHint';
      hint = card.fields[fieldKey]?.toString();
    }

    if (hint == null || hint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hint available for this card')),
      );
      return;
    }

    setState(() => _usedHint = true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('Hint'),
          ],
        ),
        content: Text(hint!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _rateCard(DifficultyRating rating) {
    // Apply hint penalty if hint was used (score will be lower)
    // This is tracked in _usedHint and can be used by scoring system
    ref
        .read(studySessionProvider.notifier)
        .rateCard(rating, usedHint: _usedHint);

    // Reset card state for next card
    setState(() {
      _showingFront = true;
      _currentFace = 1;
      _nextFace = 1;
      _goingForward = true;
      _usedHint = false;
      _isCardReversed = _determineCardOrientation();
    });
    _flipController.reset();
  }

  bool _determineCardOrientation() {
    final settings = ref.read(settingsProvider);
    final mode = settings.cardDirectionMode;

    switch (mode) {
      case 'frontFirst':
        return false; // Always show front first
      case 'backFirst':
        return true; // Always show back first
      case 'shuffle':
      default:
        return math.Random().nextBool(); // Random
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
        appBar: AppBar(title: const Text('Study')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(sessionState.error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.decks),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (!sessionState.isActive || sessionState.currentCard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study')),
        body: const LoadingIndicator(message: 'Loading cards...'),
      );
    }

    final card = sessionState.currentCard!;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${sessionState.currentCardIndex + 1}/${sessionState.cards.length}',
          ),
          actions: const [],
        ),
        body: Column(
          children: [
            // Progress bar
            StudyProgressIndicator(progress: sessionState.progress),

            // Hint used indicator (top right)
            if (_usedHint)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Hint used',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Card with floating hint button
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _flipCard,
                    onHorizontalDragEnd: (details) {
                      // For 3-face cards, only allow rating when on face 3
                      final canRate = card.isThreeFaces
                          ? _currentFace == 3
                          : !_showingFront;

                      if (!canRate) {
                        _flipCard();
                        return;
                      }
                      // Swipe gestures for rating
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! > 0) {
                          // Swipe right = correct (Good)
                          _rateCard(DifficultyRating.good);
                        } else if (details.primaryVelocity! < 0) {
                          // Swipe left = wrong (Again)
                          _rateCard(DifficultyRating.again);
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: card.isThreeFaces
                          ? _buildThreeFaceCard(theme, card)
                          : AnimatedBuilder(
                              animation: _flipAnimation,
                              builder: (context, child) {
                                final angle = _flipAnimation.value * math.pi;
                                final showFront = angle < math.pi / 2;

                                // Determine what to show based on reversed state
                                final actualFront =
                                    _isCardReversed ? card.back : card.front;
                                final actualBack =
                                    _isCardReversed ? card.front : card.back;
                                final frontIsQuestion = !_isCardReversed;

                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(angle),
                                  child: showFront
                                      ? _buildCardFace(
                                          theme,
                                          actualFront,
                                          frontIsQuestion,
                                          card.type.icon,
                                          card,
                                        )
                                      : Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..rotateY(math.pi),
                                          child: _buildCardFace(
                                            theme,
                                            actualBack,
                                            !frontIsQuestion,
                                            null,
                                            card,
                                          ),
                                        ),
                                );
                              },
                            ),
                    ),
                  ), // Close GestureDetector
                  // Floating hint button (bottom right) - only visible on front/question side
                  if (_showingFront &&
                      (!card.isThreeFaces || _currentFace == 1))
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(28),
                        color: _hasHintAvailable()
                            ? Colors.amber[600]
                            : Colors.grey[400],
                        child: InkWell(
                          onTap: _hasHintAvailable() ? _showHint : null,
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 20,
                                  color: _hasHintAvailable()
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hint',
                                  style: TextStyle(
                                    color: _hasHintAvailable()
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Tap hint or difficulty buttons
            if (card.isThreeFaces)
              _buildThreeFaceHint(theme)
            else if (_showingFront)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tap to reveal answer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              DifficultyButtons(card: card, onRate: _rateCard),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFace(
    ThemeData theme,
    String content,
    bool isFront,
    String? icon,
    dynamic card,
  ) {
    final deckAsync = ref.watch(deckProvider(widget.deckId));
    final deckEmoji = deckAsync.value != null
        ? (isFront ? deckAsync.value!.frontEmoji : deckAsync.value!.backEmoji)
        : null;

    // Check if content is an image path
    final isImage = content.isNotEmpty &&
        (content.startsWith('/') || content.contains('/'));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isFront
              ? theme.colorScheme.outline.withValues(alpha: 0.2)
              : AppColors.success.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isImage &&
                card.type != CardType.wordImage &&
                deckEmoji != null &&
                deckEmoji.isNotEmpty) ...[
              Text(deckEmoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 24),
            ],
            // Check if content is an image path
            isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(content),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          _capitalize(content),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  )
                : Text(
                    _capitalize(content),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ],
        ),
      ),
    );
  }

  bool _hasHintAvailable() {
    final sessionState = ref.read(studySessionProvider);
    final card = sessionState.currentCard;
    if (card == null) return false;

    // Get hint for the question side (what's shown first)
    // If card is reversed, the "question" is the back, so use backHint
    // Also check fields map for backward compatibility (old cards stored hints there)
    String? hint = _isCardReversed ? card.backHint : card.frontHint;

    // Fallback: check in fields map for backward compatibility
    if (hint == null || hint.isEmpty) {
      final fieldKey = _isCardReversed ? 'backHint' : 'frontHint';
      hint = card.fields[fieldKey]?.toString();
    }

    return hint != null && hint.isNotEmpty;
  }

  Widget _buildThreeFaceCard(ThemeData theme, dynamic card) {
    // Get content for current and next face
    String getContentForFace(int face) {
      switch (face) {
        case 1:
          return _capitalize(card.front);
        case 2:
          return _capitalize(card.back);
        case 3:
          return _capitalize(card.face3);
        default:
          return _capitalize(card.front);
      }
    }

    final currentContent = getContentForFace(_currentFace);
    final nextContent = getContentForFace(_nextFace);

    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        final showCurrentFace = angle < math.pi / 2;

        // During first half: show current face rotating away
        // During second half: show next face rotating in
        final displayContent = showCurrentFace ? currentContent : nextContent;
        final displayFace = showCurrentFace ? _currentFace : _nextFace;

        // Calculate the actual rotation angle
        // First half: rotate from 0 to 90 degrees
        // Second half: rotate from -90 to 0 degrees (for the back face coming in)
        final rotationAngle = showCurrentFace ? angle : angle - math.pi;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotationAngle),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Face indicators - all blue, show progress based on displayed face
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index + 1 <= displayFace;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    displayContent,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThreeFaceHint(ThemeData theme) {
    final sessionState = ref.watch(studySessionProvider);
    final card = sessionState.currentCard;

    if (_currentFace < 3) {
      final direction = _goingForward ? 'next' : 'previous';
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Tap to reveal $direction face',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      return DifficultyButtons(card: card!, onRate: _rateCard);
    }
  }
}

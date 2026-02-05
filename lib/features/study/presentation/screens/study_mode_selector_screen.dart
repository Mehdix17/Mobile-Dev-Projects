import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/constants/predefined_tags.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../cards/presentation/providers/card_provider.dart';
import '../../../cards/data/models/card_model_firestore.dart';
import '../../../decks/presentation/providers/deck_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/study_session_model.dart';

class StudyModeSelectorScreen extends ConsumerStatefulWidget {
  final String deckId;

  const StudyModeSelectorScreen({super.key, required this.deckId});

  @override
  ConsumerState<StudyModeSelectorScreen> createState() =>
      _StudyModeSelectorScreenState();
}

class _StudyModeSelectorScreenState
    extends ConsumerState<StudyModeSelectorScreen> {
  int _totalCardsCount = 10;
  final Set<String> _selectedTags = {};
  final Set<String> _selectedCardTypes = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCardsAsync = ref.watch(cardsProvider(widget.deckId));

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Game Settings'),
        ),
        body: allCardsAsync.when(
          data: (allCards) {
            // Apply filters to get filtered cards
            var filteredCards = allCards.toList();

            // Filter by tags if any selected
            if (_selectedTags.isNotEmpty) {
              filteredCards = filteredCards.where((card) {
                final cardTags = card.tags as List<String>?;
                if (cardTags == null || cardTags.isEmpty) return false;
                return _selectedTags.any((tag) => cardTags.contains(tag));
              }).toList();
            }

            // Filter by card type if any selected
            if (_selectedCardTypes.isNotEmpty) {
              filteredCards = filteredCards.where((card) {
                return _selectedCardTypes.contains(card.type.displayName);
              }).toList();
            }

            final totalAvailable = filteredCards.length;

            // Adjust max values based on available filtered cards
            final maxTotalCards = totalAvailable;

            // Ensure current selection doesn't exceed available
            if (_totalCardsCount > maxTotalCards) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _totalCardsCount = maxTotalCards > 0 ? maxTotalCards : 1;
                  });
                }
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card selection section
                  Text(
                    'Card Selection',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Total cards slider
                  _buildSliderSection(
                    theme: theme,
                    title: 'Cards to Study',
                    subtitle: 'Cards are prioritized by spaced repetition',
                    value: _totalCardsCount,
                    max: maxTotalCards,
                    min: 1,
                    icon: Icons.style,
                    color: AppColors.secondary,
                    onChanged: maxTotalCards > 0
                        ? (value) {
                            setState(() {
                              _totalCardsCount = value.round();
                            });
                          }
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Tag filter section
                  _buildTagFilterSection(theme, allCards),

                  const SizedBox(height: 16),

                  // Card type filter section
                  _buildCardTypeFilterSection(theme, allCards),

                  const SizedBox(height: 16),

                  // Card Direction section
                  _buildCardDirectionSection(theme),

                  const SizedBox(height: 20),

                  // Study modes section
                  Text(
                    'Choose Study Mode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Study modes
                  ...StudyMode.values.map((mode) {
                    final isAvailable =
                        maxTotalCards > 0 && _totalCardsCount >= mode.minCards;
                    return _StudyModeCard(
                      mode: mode,
                      isAvailable: isAvailable,
                      onTap:
                          isAvailable ? () => _startStudy(context, mode) : null,
                      minCards: mode.minCards,
                      currentCards: _totalCardsCount,
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required int value,
    required int max,
    int min = 0,
    required IconData icon,
    required Color color,
    required ValueChanged<double>? onChanged,
  }) {
    final isDisabled = max <= 0;
    final effectiveMin = min.clamp(0, max > 0 ? max : 1);
    final effectiveMax = max > 0 ? max : 1;
    final effectiveValue = value.clamp(effectiveMin, effectiveMax);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isDisabled ? Colors.grey : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? Colors.grey : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.grey.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isDisabled ? '0' : '$effectiveValue',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDisabled ? Colors.grey : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isDisabled ? Colors.grey : AppColors.primary,
              inactiveTrackColor: (isDisabled ? Colors.grey : AppColors.primary)
                  .withValues(alpha: 0.2),
              thumbColor: isDisabled ? Colors.grey : AppColors.primary,
              overlayColor: (isDisabled ? Colors.grey : AppColors.primary)
                  .withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: effectiveValue.toDouble(),
              min: effectiveMin.toDouble(),
              max: effectiveMax.toDouble(),
              divisions:
                  effectiveMax > effectiveMin ? effectiveMax - effectiveMin : 1,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$effectiveMin',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$max available',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startStudy(BuildContext context, StudyMode mode) {
    // Pass settings via query parameters
    final params = <String, String>{
      'practice': 'true',
      'totalCards': _totalCardsCount.toString(),
    };

    // Add tags filter if any selected
    if (_selectedTags.isNotEmpty) {
      params['tags'] = _selectedTags.join(',');
    }

    // Add card types filter if any selected
    if (_selectedCardTypes.isNotEmpty) {
      params['cardTypes'] = _selectedCardTypes.join(',');
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final routeName = switch (mode) {
      StudyMode.flipCard => RouteNames.flipCard,
      StudyMode.multipleChoice => RouteNames.multipleChoice,
      StudyMode.matchPairs => RouteNames.matchPairs,
    };
    context.push('$routeName/${widget.deckId}?$queryString');
  }

  Widget _buildTagFilterSection(ThemeData theme, List<dynamic> allCards) {
    // Extract all unique tags from cards
    final allTags = <String>{};
    for (final card in allCards) {
      if (card.tags != null) {
        allTags.addAll(card.tags as Iterable<String>);
      }
    }
    final sortedTags = allTags.toList()..sort();

    if (sortedTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.label, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Filter by Tags (optional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_selectedTags.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedTags.clear());
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              final tagColor =
                  PredefinedTags.getColorForTag(tag) ?? AppColors.primary;
              return FilterChip(
                label: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected ? Colors.white : tagColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                backgroundColor: tagColor.withValues(alpha: 0.1),
                selectedColor: tagColor,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: tagColor,
                  width: 1.5,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTypeFilterSection(ThemeData theme, List<dynamic> allCards) {
    // Extract all unique card types from cards
    final allCardTypes = <String>{};
    for (final card in allCards) {
      allCardTypes.add(card.type.displayName);
    }
    final sortedCardTypes = allCardTypes.toList()..sort();

    if (sortedCardTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Filter by Card Type (optional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_selectedCardTypes.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedCardTypes.clear());
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedCardTypes.map((cardType) {
              final isSelected = _selectedCardTypes.contains(cardType);
              final cardTypeEnum = CardType.values.firstWhere(
                (type) => type.displayName == cardType,
                orElse: () => CardType.basic,
              );
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cardTypeEnum.icon),
                    const SizedBox(width: 4),
                    Text(
                      cardType,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCardTypes.add(cardType);
                    } else {
                      _selectedCardTypes.remove(cardType);
                    }
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDirectionSection(ThemeData theme) {
    final settings = ref.watch(settingsProvider);
    final deckAsync = ref.watch(deckProvider(widget.deckId));

    return deckAsync.when(
      data: (deck) {
        final frontEmoji = deck?.frontEmoji ?? '🇬🇧';
        final backEmoji = deck?.backEmoji ?? '🇫🇷';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shuffle, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Card Direction',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Direction options in one row
              Row(
                children: [
                  Expanded(
                    child: _buildDirectionChip(
                      theme,
                      'Shuffle',
                      'shuffle',
                      settings.cardDirectionMode,
                      null,
                      null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildDirectionChip(
                      theme,
                      'Front First',
                      'frontFirst',
                      settings.cardDirectionMode,
                      frontEmoji,
                      null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildDirectionChip(
                      theme,
                      'Back First',
                      'backFirst',
                      settings.cardDirectionMode,
                      backEmoji,
                      null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDirectionChip(
    ThemeData theme,
    String label,
    String value,
    String currentValue,
    String? emoji,
    IconData? icon,
  ) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: () {
        ref.read(settingsProvider.notifier).setCardDirectionMode(value);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: emoji != null
                    ? Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      )
                    : icon != null
                        ? Icon(
                            icon,
                            size: 28,
                            color: isSelected
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant,
                          )
                        : Icon(
                            Icons.shuffle,
                            size: 28,
                            color: isSelected
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyModeCard extends StatelessWidget {
  final StudyMode mode;
  final bool isAvailable;
  final VoidCallback? onTap;
  final int minCards;
  final int currentCards;

  const _StudyModeCard({
    required this.mode,
    required this.isAvailable,
    this.onTap,
    required this.minCards,
    required this.currentCards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAvailable
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAvailable
                  ? theme.colorScheme.outline.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(
                    mode.icon,
                    style: TextStyle(
                      fontSize: 32,
                      color: isAvailable ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isAvailable
                            ? null
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Requires at least $minCards cards',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isAvailable
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

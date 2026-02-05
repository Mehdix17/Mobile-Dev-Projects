import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/constants/predefined_tags.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/card_provider.dart';

class CardDetailScreen extends ConsumerWidget {
  final String cardId;
  final String deckId;

  const CardDetailScreen({
    super.key,
    required this.cardId,
    required this.deckId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardAsync = ref.watch(cardProvider((deckId, cardId)));

    return cardAsync.when(
      data: (card) {
        if (card == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Card not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(card.type.displayName),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Card'),
                      content: const Text(
                        'Are you sure you want to delete this card?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref
                        .read(cardListProvider(card.deckId).notifier)
                        .deleteCard(card.id);
                    if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Show image if front is a path (Image card), otherwise show text
                      card.front.isNotEmpty &&
                              (card.front.startsWith('/') ||
                                  card.front.contains('/'))
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(card.front),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    card.front,
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                },
                              ),
                            )
                          : Text(
                              card.front,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                      const SizedBox(height: 16),
                      Divider(color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        card.back,
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status and stats
                _buildInfoSection(theme, 'Status', [
                  _InfoRow(
                    label: 'Status',
                    value: card.status.displayName,
                    valueColor: _getStatusColor(card.status),
                  ),
                  _InfoRow(
                    label: 'Next Review',
                    value: card.nextReviewDate.toRelativeString(),
                  ),
                  _InfoRow(
                    label: 'Interval',
                    value: '${card.interval.toStringAsFixed(2)} days',
                  ),
                  _InfoRow(
                    label: 'Ease Factor',
                    value: card.easeFactor.toStringAsFixed(2),
                  ),
                ]),
                const SizedBox(height: 16),

                // Statistics
                _buildInfoSection(theme, 'Statistics', [
                  _InfoRow(
                    label: 'Total Reviews',
                    value: card.totalReviews.toString(),
                  ),
                  _InfoRow(
                    label: 'Correct',
                    value: card.timesCorrect.toString(),
                    valueColor: AppColors.success,
                  ),
                  _InfoRow(
                    label: 'Incorrect',
                    value: card.timesIncorrect.toString(),
                    valueColor: AppColors.error,
                  ),
                  _InfoRow(
                    label: 'Accuracy',
                    value: '${(card.accuracy * 100).toStringAsFixed(0)}%',
                  ),
                ]),
                const SizedBox(height: 16),

                // Tags
                if (card.tags.isNotEmpty) ...[
                  Text(
                    'Tags',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: card.tags.map((tag) {
                      final tagColor = PredefinedTags.getColorForTag(tag) ??
                          AppColors.primary;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: tagColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: tagColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(
              '${RouteNames.cardEditor}?deckId=${card.deckId}&cardId=$cardId',
            ),
            child: const Icon(Icons.edit),
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

  Widget _buildInfoSection(ThemeData theme, String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: rows.map((row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      row.value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: row.valueColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString()) {
      case 'CardStatus.newCard':
        return AppColors.newCard;
      case 'CardStatus.learning':
        return AppColors.learning;
      case 'CardStatus.review':
        return AppColors.review;
      case 'CardStatus.mastered':
        return AppColors.mastered;
      default:
        return AppColors.primary;
    }
  }
}

class _InfoRow {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
}

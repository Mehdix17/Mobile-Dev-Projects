import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../cards/data/models/card_model.dart';
import '../../../cards/presentation/providers/card_provider.dart';
import '../providers/deck_provider.dart';

class DeckDetailScreen extends ConsumerWidget {
  final String deckId;

  const DeckDetailScreen({super.key, required this.deckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deckAsync = ref.watch(deckProvider(deckId));
    final cardsAsync = ref.watch(cardListProvider(deckId));

    return deckAsync.when(
      data: (deck) {
        if (deck == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Deck not found')),
          );
        }

        final color = Color(deck.color.colorValue);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: color,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    deck.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.8),
                          color,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        deck.icon,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => context.push(
                      '${RouteNames.deckEditor}?deckId=$deckId',
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      switch (value) {
                        case 'export':
                          context.push('${RouteNames.export}?deckId=$deckId');
                          break;
                        case 'delete':
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Deck'),
                              content: const Text(
                                'Are you sure you want to delete this deck? All cards will be lost.',
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
                                .read(deckListProvider.notifier)
                                .deleteDeck(deck.id);
                            if (context.mounted) context.pop();
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.file_upload),
                            SizedBox(width: 8),
                            Text('Export'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Stats bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip(
                              label: 'Cards',
                              value: deck.cardCount.toString(),
                              color: theme.colorScheme.primary,
                            ),
                            _StatChip(
                              label: 'New',
                              value: deck.newCardCount.toString(),
                              color: Colors.blue,
                            ),
                            _StatChip(
                              label: 'Due',
                              value: deck.dueCardCount.toString(),
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: deck.cardCount > 0
                            ? () => context.push(
                                  '${RouteNames.studyModeSelector}/$deckId',
                                )
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Study'),
                      ),
                    ],
                  ),
                ),
              ),
              // Description
              if (deck.description.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      deck.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              // Cards list header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Cards',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Cards list
              cardsAsync.when(
                data: (cards) {
                  if (cards.isEmpty) {
                    return const SliverFillRemaining(
                      child: EmptyState(
                        icon: '📝',
                        title: 'No Cards Yet',
                        message: 'Add your first flashcard to this deck',
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final card = cards[index];
                        // Check if it's an image card (front contains path)
                        final isImageCard = card.front.isNotEmpty &&
                            (card.front.startsWith('/') ||
                                card.front.contains('/'));
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Text(
                              card.type.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          title: Text(
                            isImageCard ? card.type.displayName : card.front,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            card.back,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(card.status)
                                  .withValues(alpha: 0.1),
                              border: Border.all(
                                color: _getStatusColor(card.status),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              card.status.displayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getStatusColor(card.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          onTap: () => context.push(
                            '${RouteNames.cardDetail}?deckId=$deckId&cardId=${card.id}',
                          ),
                        );
                      },
                      childCount: cards.length,
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: LoadingIndicator(),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $error')),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(
              '${RouteNames.cardEditor}?deckId=$deckId',
            ),
            child: const Icon(Icons.add),
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

  Color _getStatusColor(CardStatus status) {
    switch (status) {
      case CardStatus.newCard:
        return AppColors.newCard;
      case CardStatus.learning:
        return AppColors.learning;
      case CardStatus.review:
        return AppColors.review;
      case CardStatus.mastered:
        return AppColors.mastered;
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
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
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

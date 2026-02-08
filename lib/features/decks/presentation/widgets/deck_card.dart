import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/deck_model.dart';
import '../../../../core/router/route_names.dart';

class DeckCard extends StatelessWidget {
  final DeckModel deck;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onPublish;

  const DeckCard({
    super.key,
    required this.deck,
    this.onDelete,
    this.onToggleStar,
    this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(deck.color.colorValue);

    return InkWell(
      onTap: () => context.push('${RouteNames.deckDetail}/${deck.id}'),
      onLongPress: () => _showActionsMenu(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.85),
              color,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    deck.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  Row(
                    children: [
                      if (deck.isStarred)
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                      if (deck.isPublished)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.public,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      if (deck.dueCardCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${deck.dueCardCount}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(
                deck.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${deck.cardCount} cards',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (deck.tags.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deck.tags.take(2).join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(deck.isStarred ? Icons.star : Icons.star_outline),
              title: Text(deck.isStarred ? 'Unstar Deck' : 'Star Deck'),
              onTap: () {
                Navigator.pop(ctx);
                onToggleStar?.call();
              },
            ),
            if (!deck.isPublished)
              ListTile(
                leading: const Icon(Icons.publish),
                title: const Text('Publish to Marketplace'),
                onTap: () {
                  Navigator.pop(ctx);
                  onPublish?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Deck',
                  style: TextStyle(color: Colors.red),),
              onTap: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

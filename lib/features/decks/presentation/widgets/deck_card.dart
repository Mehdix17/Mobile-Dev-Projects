import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/deck_model.dart';
import '../../../../core/router/route_names.dart';

class DeckCard extends StatelessWidget {
  final DeckModel deck;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onPublish;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;

  const DeckCard({
    super.key,
    required this.deck,
    this.onDelete,
    this.onToggleStar,
    this.onPublish,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color difficultyColor(String difficulty) {
      switch (difficulty.toLowerCase()) {
        case 'beginner':
          return Colors.green;
        case 'intermediate':
          return Colors.orange;
        case 'advanced':
          return Colors.redAccent;
        default:
          return Colors.grey;
      }
    }

    return InkWell(
      onTap: isSelectionMode
          ? onSelect
          : () => context.push('${RouteNames.deckDetail}/${deck.id}'),
      onLongPress: isSelectionMode ? null : onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary,
                      width: 3,
                    )
                  : Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              // further reduce top padding so title/icon row moves closer to card top
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top-right status icons (menu moved to fixed position)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // removed top-right star icon — starring is available via actions menu
                      // published icon removed per UX request
                    ],
                  ),
                  const SizedBox(height: 0),
                  // Icon + title on the same row (marketplace-style with trailing control)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        deck.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 8),

                      // Title expands to push the control to the far right
                      Expanded(
                        child: Text(
                          deck.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 0),

                      // Top-right control: options menu (or checkbox in selection mode)
                      isSelectionMode
                          ? GestureDetector(
                              onTap: onSelect,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                alignment: Alignment.center,
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            )
                          : SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.black87,
                                  size: 18,
                                ),
                                onPressed: () => _showActionsMenu(context),
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description (if available)
                  if (deck.description.isNotEmpty) ...[
                    Text(
                      deck.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Difficulty badge + predefined + card-count + flags (single line)
                  Row(
                    children: [
                      if ((deck.difficulty ?? '').isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: difficultyColor(deck.difficulty!)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.signal_cellular_alt,
                                size: 12,
                                color: difficultyColor(deck.difficulty!),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${deck.difficulty![0].toUpperCase()}${deck.difficulty!.substring(1)}',
                                style: TextStyle(
                                  color: difficultyColor(deck.difficulty!),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // small gap (match gap used around predefined)
                        const SizedBox(width: 6),
                      ],

                      // Card count styled in blue (matches predefined badge color)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${deck.cardCount} cards',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Language flags now appear AFTER the card-count badge
                      // show only unique flags (dedupe front/back)
                      Builder(
                        builder: (ctx) {
                          final flags = <String>[];
                          if (deck.frontEmoji != null &&
                              deck.frontEmoji!.isNotEmpty) {
                            flags.add(deck.frontEmoji!);
                          }
                          if (deck.backEmoji != null &&
                              deck.backEmoji!.isNotEmpty &&
                              deck.backEmoji != deck.frontEmoji) {
                            flags.add(deck.backEmoji!);
                          }
                          return Row(
                            children: flags
                                .map(
                                  (f) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text(
                                      f,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),

                      // Tags (moved inline) — exclude 'predefined' tag to avoid duplication
                      if (deck.tags
                          .where((t) => t.toLowerCase() != 'predefined')
                          .isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            deck.tags
                                .where((t) => t.toLowerCase() != 'predefined')
                                .take(2)
                                .join(', '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                    ],
                  ),

                  // tightened spacing below the badges row
                  const SizedBox(height: 2),

                  // local difficulty color helper
                  // (kept near usage to avoid global change)
                ],
              ),
            ),
          ),
        ],
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
            if (!deck.isPublished && !deck.isPredefined)
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
              title: const Text(
                'Delete Deck',
                style: TextStyle(color: Colors.red),
              ),
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

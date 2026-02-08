import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/deck_provider.dart';
import '../widgets/deck_card.dart';
import '../../data/models/deck_model.dart';

class DeckListScreen extends ConsumerStatefulWidget {
  const DeckListScreen({super.key});

  @override
  ConsumerState<DeckListScreen> createState() => _DeckListScreenState();
}

class _DeckListScreenState extends ConsumerState<DeckListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedLabels = {};
  bool _showStarredOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeckModel> _filterDecks(List<DeckModel> decks) {
    var filtered = decks;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((deck) {
        return deck.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            deck.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by labels
    if (_selectedLabels.isNotEmpty) {
      filtered = filtered.where((deck) {
        return deck.tags.any((tag) => _selectedLabels.contains(tag));
      }).toList();
    }

    // Filter by starred
    if (_showStarredOnly) {
      filtered = filtered.where((deck) => deck.isStarred).toList();
    }

    return filtered;
  }

  Set<String> _getAllLabels(List<DeckModel> decks) {
    final labels = <String>{};
    for (final deck in decks) {
      labels.addAll(deck.tags);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decksAsync = ref.watch(deckListProvider);

    return Scaffold(
      body: decksAsync.when(
        data: (allDecks) {
          final filteredDecks = _filterDecks(allDecks);
          final allLabels = _getAllLabels(allDecks);
          final starredDecks = allDecks.where((d) => d.isStarred).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(deckListProvider.notifier).loadDecks();
            },
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: const Text('My Decks'),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _showStarredOnly ? Icons.star : Icons.star_outline,
                        color: _showStarredOnly ? Colors.amber : null,
                      ),
                      onPressed: () {
                        setState(() {
                          _showStarredOnly = !_showStarredOnly;
                        });
                      },
                      tooltip: _showStarredOnly ? 'Show All' : 'Show Starred',
                    ),
                  ],
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search decks...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),

                // Label Filters
                if (allLabels.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allLabels.length,
                        itemBuilder: (context, index) {
                          final label = allLabels.elementAt(index);
                          final isSelected = _selectedLabels.contains(label);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedLabels.add(label);
                                  } else {
                                    _selectedLabels.remove(label);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Active Filters Summary
                if (_selectedLabels.isNotEmpty ||
                    _showStarredOnly ||
                    _searchQuery.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8,),
                      child: Row(
                        children: [
                          Text(
                            '${filteredDecks.length} of ${allDecks.length} decks',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedLabels.isNotEmpty ||
                              _showStarredOnly ||
                              _searchQuery.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedLabels.clear();
                                  _showStarredOnly = false;
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear filters'),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Starred Decks Section
                if (!_showStarredOnly &&
                    starredDecks.isNotEmpty &&
                    _searchQuery.isEmpty &&
                    _selectedLabels.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Starred Decks',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!_showStarredOnly &&
                    starredDecks.isNotEmpty &&
                    _searchQuery.isEmpty &&
                    _selectedLabels.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: starredDecks.length,
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 160,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: DeckCard(
                                deck: starredDecks[index],
                                onDelete: () =>
                                    _deleteDeck(starredDecks[index]),
                                onToggleStar: () =>
                                    _toggleStarred(starredDecks[index]),
                                onPublish: () =>
                                    _publishDeck(starredDecks[index]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // All Decks Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      _showStarredOnly ? 'Starred Decks' : 'All Decks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Decks Grid or Empty State
                if (filteredDecks.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      icon: _showStarredOnly ? '⭐' : '📚',
                      title: _showStarredOnly
                          ? 'No Starred Decks'
                          : 'No Decks Found',
                      message: _showStarredOnly
                          ? 'Star your favorite decks to see them here'
                          : (_searchQuery.isNotEmpty ||
                                  _selectedLabels.isNotEmpty)
                              ? 'Try adjusting your filters'
                              : 'Create your first deck to start learning!',
                      actionLabel: _showStarredOnly ? null : 'Create Deck',
                      onAction: _showStarredOnly
                          ? null
                          : () => _showNewDeckOptions(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => DeckCard(
                          deck: filteredDecks[index],
                          onDelete: () => _deleteDeck(filteredDecks[index]),
                          onToggleStar: () =>
                              _toggleStarred(filteredDecks[index]),
                          onPublish: () => _publishDeck(filteredDecks[index]),
                        ),
                        childCount: filteredDecks.length,
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(deckListProvider.notifier).loadDecks(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewDeckOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('New Deck'),
      ),
    );
  }

  void _deleteDeck(DeckModel deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text(
            'Are you sure you want to delete "${deck.name}"? This will also delete all cards in this deck.',),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(deckListProvider.notifier).deleteDeck(deck.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${deck.name} deleted')),
        );
      }
    }
  }

  void _toggleStarred(DeckModel deck) async {
    await ref
        .read(deckListProvider.notifier)
        .toggleStarred(deck.id, !deck.isStarred);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              deck.isStarred ? 'Removed from starred' : 'Added to starred',),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _publishDeck(DeckModel deck) async {
    if (deck.isPublished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck is already published')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Deck'),
        content: Text(
            'Publish "${deck.name}" to the marketplace? Other users will be able to see and import it.',),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(deckListProvider.notifier).publishDeck(deck.id, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${deck.name} published to marketplace')),
        );
      }
    }
  }

  void _showNewDeckOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _NewDeckOptionsSheet(),
    );
  }
}

class _NewDeckOptionsSheet extends StatelessWidget {
  const _NewDeckOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Create New Deck',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to create your deck',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Create from scratch option
            _OptionCard(
              icon: Icons.add_box_outlined,
              title: 'Create from Scratch',
              description: 'Start with an empty deck and add your own cards',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.deckEditor);
              },
            ),
            const SizedBox(height: 12),

            // Import option
            _OptionCard(
              icon: Icons.file_download_outlined,
              title: 'Import Deck',
              description: 'Import cards from CSV, JSON, or Anki files',
              color: AppColors.secondary,
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.import);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/deck_provider.dart';
import '../widgets/deck_card.dart';
import '../../data/models/deck_model.dart';

/// Language name → flag emoji mapping
const Map<String, String> _languageFlags = {
  'English': '🇬🇧',
  'French': '🇫🇷',
  'Spanish': '🇪🇸',
  'German': '🇩🇪',
  'Italian': '🇮🇹',
  'Portuguese': '🇵🇹',
  'Russian': '🇷🇺',
  'Chinese': '🇨🇳',
  'Japanese': '🇯🇵',
  'Korean': '🇰🇷',
  'Arabic': '🇸🇦',
  'Hindi': '🇮🇳',
  'Turkish': '🇹🇷',
  'Dutch': '🇳🇱',
  'Polish': '🇵🇱',
  'Swedish': '🇸🇪',
  'Norwegian': '🇳🇴',
  'Danish': '🇩🇰',
  'Finnish': '🇫🇮',
  'Greek': '🇬🇷',
  'Czech': '🇨🇿',
  'Romanian': '🇷🇴',
  'Hungarian': '🇭🇺',
  'Ukrainian': '🇺🇦',
  'Thai': '🇹🇭',
  'Vietnamese': '🇻🇳',
  'Indonesian': '🇮🇩',
  'Malay': '🇲🇾',
};

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
  String _selectedLanguage = 'All';
  String _selectedDifficulty = 'All';

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedDeckIds = {};

  void _enterSelectionMode(String deckId) {
    setState(() {
      _isSelectionMode = true;
      _selectedDeckIds.add(deckId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedDeckIds.clear();
    });
  }

  void _toggleSelection(String deckId) {
    setState(() {
      if (_selectedDeckIds.contains(deckId)) {
        _selectedDeckIds.remove(deckId);
        if (_selectedDeckIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedDeckIds.add(deckId);
      }
    });
  }

  void _selectAll(List<DeckModel> decks) {
    setState(() {
      _selectedDeckIds.addAll(decks.map((d) => d.id));
    });
  }

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

    // Filter by language (match name, emoji → name, or language code)
    if (_selectedLanguage != 'All') {
      filtered = filtered.where((deck) {
        final frontMatches = deck.frontLanguageName == _selectedLanguage ||
            (deck.frontEmoji != null &&
                _languageNameFromEmoji(deck.frontEmoji!) ==
                    _selectedLanguage) ||
            (deck.frontLanguageCode != null &&
                deck.frontLanguageCode!.toUpperCase() ==
                    _selectedLanguage.toUpperCase());

        final backMatches = deck.backLanguageName == _selectedLanguage ||
            (deck.backEmoji != null &&
                _languageNameFromEmoji(deck.backEmoji!) == _selectedLanguage) ||
            (deck.backLanguageCode != null &&
                deck.backLanguageCode!.toUpperCase() ==
                    _selectedLanguage.toUpperCase());

        return frontMatches || backMatches;
      }).toList();
    }

    // Filter by difficulty
    if (_selectedDifficulty != 'All') {
      filtered = filtered.where((deck) {
        final diff = (deck.difficulty ?? '').toLowerCase();
        return diff == _selectedDifficulty.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  // Normalize language identifiers so the dropdown consistently shows `flag + name`.
  String _languageNameFromEmoji(String emoji) {
    for (final entry in _languageFlags.entries) {
      if (entry.value == emoji) return entry.key;
    }
    return emoji; // fallback — will be shown as-is
  }

  List<String> _getAvailableLanguages(List<DeckModel> decks) {
    final langs = <String>{};
    for (final d in decks) {
      // Front language: prefer explicit name, then resolve emoji → name, then code
      if (d.frontLanguageName != null && d.frontLanguageName!.isNotEmpty) {
        langs.add(d.frontLanguageName!);
      } else if (d.frontEmoji != null && d.frontEmoji!.isNotEmpty) {
        langs.add(_languageNameFromEmoji(d.frontEmoji!));
      } else if (d.frontLanguageCode != null &&
          d.frontLanguageCode!.isNotEmpty) {
        langs.add(d.frontLanguageCode!.toUpperCase());
      }

      // Back language: same order
      if (d.backLanguageName != null && d.backLanguageName!.isNotEmpty) {
        langs.add(d.backLanguageName!);
      } else if (d.backEmoji != null && d.backEmoji!.isNotEmpty) {
        langs.add(_languageNameFromEmoji(d.backEmoji!));
      } else if (d.backLanguageCode != null && d.backLanguageCode!.isNotEmpty) {
        langs.add(d.backLanguageCode!.toUpperCase());
      }
    }

    // Ensure deterministic ordering and no duplicates
    final sorted = langs.toList()..sort();
    return ['All', ...sorted];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decksAsync = ref.watch(deckListProvider);

    final Widget body = Scaffold(
      body: decksAsync.when(
        data: (allDecks) {
          final filteredDecks = _filterDecks(allDecks);
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
                  leading: _isSelectionMode
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _exitSelectionMode,
                        )
                      : null,
                  title: _isSelectionMode
                      ? Text('${_selectedDeckIds.length} selected')
                      : const Text('My Decks'),
                  actions: _isSelectionMode
                      ? [
                          IconButton(
                            icon: const Icon(Icons.select_all),
                            tooltip: 'Select All',
                            onPressed: () => _selectAll(filteredDecks),
                          ),
                          IconButton(
                            icon: const Icon(Icons.star_outline),
                            tooltip: 'Star Selected',
                            onPressed: _selectedDeckIds.isEmpty
                                ? null
                                : () => _bulkToggleStar(allDecks),
                          ),
                          IconButton(
                            icon: const Icon(Icons.publish),
                            tooltip: 'Publish Selected',
                            onPressed: _selectedDeckIds.isEmpty
                                ? null
                                : () => _bulkPublish(allDecks),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Selected',
                            onPressed: _selectedDeckIds.isEmpty
                                ? null
                                : () => _bulkDelete(allDecks),
                          ),
                        ]
                      : [
                          IconButton(
                            icon: Icon(
                              _showStarredOnly
                                  ? Icons.star
                                  : Icons.star_outline,
                              color: _showStarredOnly ? Colors.amber : null,
                            ),
                            onPressed: () {
                              setState(() {
                                _showStarredOnly = !_showStarredOnly;
                              });
                            },
                            tooltip:
                                _showStarredOnly ? 'Show All' : 'Show Starred',
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

                // Language & Difficulty Filters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Builder(
                      builder: (context) {
                        // compute available languages and ensure the selected value
                        // is valid (prevents DropdownButton assertion after deletes)
                        final availableLanguages =
                            _getAvailableLanguages(allDecks);
                        if (!availableLanguages.contains(_selectedLanguage)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _selectedLanguage = 'All');
                            }
                          });
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _DeckLanguageFilter(
                                value: availableLanguages
                                        .contains(_selectedLanguage)
                                    ? _selectedLanguage
                                    : 'All',
                                items: availableLanguages,
                                onChanged: (v) =>
                                    setState(() => _selectedLanguage = v),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DeckDifficultyFilter(
                                value: _selectedDifficulty,
                                onChanged: (v) =>
                                    setState(() => _selectedDifficulty = v),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Active Filters Summary
                if (_selectedLabels.isNotEmpty ||
                    _showStarredOnly ||
                    _searchQuery.isNotEmpty ||
                    _selectedLanguage != 'All' ||
                    _selectedDifficulty != 'All')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                              _searchQuery.isNotEmpty ||
                              _selectedLanguage != 'All' ||
                              _selectedDifficulty != 'All')
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedLabels.clear();
                                  _showStarredOnly = false;
                                  _searchQuery = '';
                                  _searchController.clear();
                                  _selectedLanguage = 'All';
                                  _selectedDifficulty = 'All';
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
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final deck = starredDecks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DeckCard(
                              deck: deck,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedDeckIds.contains(deck.id),
                              onSelect: () => _toggleSelection(deck.id),
                              onLongPress: () => _enterSelectionMode(deck.id),
                              onDelete: () => _deleteDeck(deck),
                              onToggleStar: () => _toggleStarred(deck),
                              onPublish: () => _publishDeck(deck),
                            ),
                          );
                        },
                        childCount: starredDecks.length,
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
                      // remove in-card "Create Deck" button — there's already
                      // a floating action button at the bottom-right
                      actionLabel: null,
                      onAction: null,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final deck = filteredDecks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DeckCard(
                              deck: deck,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedDeckIds.contains(deck.id),
                              onSelect: () => _toggleSelection(deck.id),
                              onLongPress: () => _enterSelectionMode(deck.id),
                              onDelete: () => _deleteDeck(deck),
                              onToggleStar: () => _toggleStarred(deck),
                              onPublish: () => _publishDeck(deck),
                            ),
                          );
                        },
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

    // Wrap with PopScope only in selection mode
    if (_isSelectionMode) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _exitSelectionMode();
        },
        child: body,
      );
    }
    return body;
  }

  void _deleteDeck(DeckModel deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text(
          'Are you sure you want to delete "${deck.name}"? This will also delete all cards in this deck.',
        ),
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
            deck.isStarred ? 'Removed from starred' : 'Added to starred',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _publishDeck(DeckModel deck) async {
    // Guest mode check
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Sign in to publish decks to the marketplace'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade700,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    if (deck.isPredefined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Predefined decks are already on the marketplace'),
        ),
      );
      return;
    }

    if (deck.isPublished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deck is already published')),
      );
      return;
    }

    await ref.read(deckListProvider.notifier).publishDeck(deck.id, true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${deck.name} published to marketplace')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Bulk actions
  // ---------------------------------------------------------------------------

  Future<void> _bulkToggleStar(List<DeckModel> allDecks) async {
    final selected =
        allDecks.where((d) => _selectedDeckIds.contains(d.id)).toList();
    final notifier = ref.read(deckListProvider.notifier);
    await notifier.bulkToggleStar(
      selected.map((d) => d.id).toList(),
      selected.map((d) => !d.isStarred).toList(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Toggled star for ${selected.length} deck(s)')),
      );
      _exitSelectionMode();
    }
  }

  Future<void> _bulkPublish(List<DeckModel> allDecks) async {
    // Guest mode check
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Sign in to publish decks to the marketplace'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade700,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    final selected =
        allDecks.where((d) => _selectedDeckIds.contains(d.id)).toList();
    final unpublished = selected.where((d) => !d.isPublished).toList();
    if (unpublished.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All selected decks are already published'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Decks'),
        content:
            Text('Publish ${unpublished.length} deck(s) to the marketplace?'),
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
      final notifier = ref.read(deckListProvider.notifier);
      await notifier.bulkPublish(unpublished.map((d) => d.id).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${unpublished.length} deck(s) published')),
        );
        _exitSelectionMode();
      }
    }
  }

  Future<void> _bulkDelete(List<DeckModel> allDecks) async {
    final count = _selectedDeckIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Decks'),
        content: Text(
          'Are you sure you want to delete $count deck(s)? This will also delete all cards in these decks.',
        ),
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
      final notifier = ref.read(deckListProvider.notifier);
      await notifier.bulkDelete(_selectedDeckIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count deck(s) deleted')),
        );
        _exitSelectionMode();
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

// ---------------------------------------------------------------------------
// Filter widgets for deck list
// ---------------------------------------------------------------------------

class _DeckLanguageFilter extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DeckLanguageFilter({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = value != 'All';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down,
            // ignore: require_trailing_commas
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          isDense: true,
          isExpanded: true,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          items: items.map((lang) {
            // Lookup flag by language name; if lang itself is a flag emoji, use it.
            String? flag = _languageFlags[lang];
            final isEmoji =
                RegExp(r'[\u{1F1E6}-\u{1F1FF}]', unicode: true).hasMatch(lang);
            if (flag == null && isEmoji) flag = lang;

            return DropdownMenuItem(
              value: lang,
              child: Row(
                children: [
                  if (lang == 'All')
                    Icon(
                      Icons.translate,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  else
                    Text(flag ?? '🏳️', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      lang,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight:
                            lang == value ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _DeckDifficultyFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DeckDifficultyFilter({
    required this.value,
    required this.onChanged,
  });

  static const _items = ['All', 'Beginner', 'Intermediate', 'Advanced'];

  static Color _color(String item) {
    switch (item.toLowerCase()) {
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

  static IconData _icon(String item) {
    switch (item.toLowerCase()) {
      case 'beginner':
        return Icons.signal_cellular_alt_1_bar;
      case 'intermediate':
        return Icons.signal_cellular_alt_2_bar;
      case 'advanced':
        return Icons.signal_cellular_alt;
      default:
        return Icons.signal_cellular_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = value != 'All';
    final activeColor = isActive ? _color(value) : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isActive ? activeColor.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? activeColor.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          isDense: true,
          isExpanded: true,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          items: _items.map((item) {
            final itemColor = _color(item);
            return DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Icon(
                    _icon(item),
                    size: 16,
                    color: item == 'All'
                        ? theme.colorScheme.onSurfaceVariant
                        : itemColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item,
                    style: TextStyle(
                      color: item == 'All'
                          ? theme.colorScheme.onSurface
                          : itemColor,
                      fontWeight:
                          item == value ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
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

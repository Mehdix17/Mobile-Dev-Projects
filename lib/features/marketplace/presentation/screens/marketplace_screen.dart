import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../shared/services/predefined_decks_loader.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Marketplace'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Browse'),
              Tab(text: 'My Shared'),
              Tab(text: 'Import/Export'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BrowseTab(),
            _MySharedTab(),
            _ImportExportTab(),
          ],
        ),
      ),
    );
  }
}

// Browse Tab - Discover and import shared decks
class _BrowseTab extends ConsumerStatefulWidget {
  const _BrowseTab();

  @override
  ConsumerState<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<_BrowseTab> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isLoadingPredefined = false;

  final predefinedDecks = [
    {
      'name': 'English Basics',
      'description': 'Common phrases, greetings, and polite expressions',
      'icon': '🗣️',
      'cards': 20,
    },
    {
      'name': 'Basic Math',
      'description': 'Arithmetic, geometry, and math fundamentals',
      'icon': '🔢',
      'cards': 20,
    },
    {
      'name': 'Multilingual Basics',
      'description': 'English/French/Spanish basics',
      'icon': '🌍',
      'cards': 20,
    },
    {
      'name': 'World Geography',
      'description': 'Countries, capitals, and landmarks',
      'icon': '🗺️',
      'cards': 20,
    },
    {
      'name': 'Programming Fundamentals',
      'description': 'Basic programming concepts',
      'icon': '💻',
      'cards': 20,
    },
    {
      'name': 'Science Vocabulary',
      'description': 'Biology, chemistry, and physics terms',
      'icon': '🔬',
      'cards': 20,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search decks...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All',
                    'Popular',
                    'Recent',
                    'Trending',
                    'Top Rated',
                  ].map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Deck List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Predefined Decks Section
              _buildPredefinedDecksSection(theme, colorScheme),
              const SizedBox(height: 24),

              // Community Decks Section (placeholder)
              _buildCommunityDecksSection(theme, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPredefinedDecksSection(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.stars, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Predefined Decks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Starter decks to help you begin learning',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...predefinedDecks.map(
          (deck) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  deck['icon'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              title: Text(deck['name'] as String),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(deck['description'] as String),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.style, size: 16),
                      const SizedBox(width: 4),
                      Text('${deck['cards']} cards'),
                    ],
                  ),
                ],
              ),
              trailing: _isLoadingPredefined
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () =>
                          _importPredefinedDeck(deck['name'] as String),
                    ),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityDecksSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              'Community Decks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Decks shared by the community',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        // Placeholder for community decks
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Community decks coming soon',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _importPredefinedDeck(String deckName) async {
    setState(() {
      _isLoadingPredefined = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final loader = PredefinedDecksLoader(userId: userId);
      final deckId = await loader.importPredefinedDeck(deckName);

      if (deckId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$deckName imported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing deck: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPredefined = false;
        });
      }
    }
  }
}

// My Shared Tab - Manage decks you've shared
class _MySharedTab extends ConsumerWidget {
  const _MySharedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // TODO: Connect to real shared decks provider
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Empty state for now
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Icon(
                Icons.upload_file,
                size: 80,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No Shared Decks Yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your decks with the community',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // TODO: Navigate to deck selection for sharing
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon')),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share a Deck'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Import/Export Tab - Import and export deck files
class _ImportExportTab extends ConsumerWidget {
  const _ImportExportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Import Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.file_download,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Import Deck',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Import decks from files or QR codes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to import screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Import from file feature coming soon',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.file_upload),
                        label: const Text('From File'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement QR import
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR import feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Export Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.file_upload,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Export Deck',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Export your decks to share with others',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to export screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Export to file feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('To File'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement QR export
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR export feature coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code),
                        label: const Text('As QR'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Quick Info
        Card(
          color: colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Supported Formats',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• JSON format (.json)\n'
                  '• CSV format (.csv)\n'
                  '• QR codes for quick sharing',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

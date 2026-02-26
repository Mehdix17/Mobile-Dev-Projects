import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/services/predefined_decks_loader.dart';
import '../../../decks/presentation/providers/deck_provider.dart';

/// Language name → flag emoji mapping (shared across marketplace)
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

// Robust lookup for a language name (handles case, short codes, emoji, partial matches
// and region-aware locale subtags like `en-US` → 🇺🇸)
String? _flagForLanguageName(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;

  // If the input already *is* a flag emoji (or contains one) return it directly.
  final flagEmojiRegex = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);
  final emojiMatch = flagEmojiRegex.firstMatch(s);
  if (emojiMatch != null) return emojiMatch.group(0);

  // Normalize separators so locale codes like `en-US` or `en_US` are handled.
  final normalized = s.replaceAll('_', '-').trim();

  // Helper: convert an ISO-3166 alpha-2 country code (e.g. 'US') to flag emoji.
  String? countryCodeToFlag(String code) {
    if (!RegExp(r'^[A-Za-z]{2}\$').hasMatch(code)) return null;
    final up = code.toUpperCase();
    final first = 0x1F1E6 + up.codeUnitAt(0) - 65;
    final second = 0x1F1E6 + up.codeUnitAt(1) - 65;
    return String.fromCharCodes([first, second]);
  }

  // If input looks like a locale with a region subtag (e.g. en-US, pt-BR), prefer the region flag.
  final parts = normalized.split('-').where((t) => t.isNotEmpty).toList();
  if (parts.length > 1) {
    final region = parts[1];
    final regionFlag = countryCodeToFlag(region);
    if (regionFlag != null) return regionFlag;
  }

  // Recognize two-letter locale prefixes and map them (en, ar, fr, de, es, it, pt, ru, zh, ja, ko, hi)
  const codeMap = {
    'en': 'English',
    'ar': 'Arabic',
    'fr': 'French',
    'de': 'German',
    'es': 'Spanish',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'hi': 'Hindi',
  };

  final firstToken = parts.isNotEmpty ? parts.first.toLowerCase() : '';
  if (codeMap.containsKey(firstToken)) {
    return _languageFlags[codeMap[firstToken]];
  }

  // direct map match (case-sensitive)
  if (_languageFlags.containsKey(s)) return _languageFlags[s];

  // case-insensitive direct match
  final caseInsensitive = _languageFlags.entries.firstWhere(
    (e) => e.key.toLowerCase() == s.toLowerCase(),
    orElse: () => const MapEntry('', ''),
  );
  if (caseInsensitive.key.isNotEmpty) return caseInsensitive.value;

  // Title-case tokens and retry (handles 'english (us)' or 'english-us')
  final tokens = normalized
      .split(RegExp(r'[\s_\-()]+'))
      .where((t) => t.isNotEmpty)
      .toList();
  final title = tokens
      .map((t) => t[0].toUpperCase() + t.substring(1).toLowerCase())
      .join(' ');
  if (_languageFlags.containsKey(title)) return _languageFlags[title];

  // If any token is a 2-letter country code (e.g. 'us', 'br'), return that flag.
  for (final t in tokens) {
    if (RegExp(r'^[A-Za-z]{2}\$').hasMatch(t)) {
      final flag = countryCodeToFlag(t);
      if (flag != null) return flag;
    }
  }

  // partial match: check if any known language name contains the provided string
  for (final entry in _languageFlags.entries) {
    final key = entry.key.toLowerCase();
    if (key.contains(normalized.toLowerCase()) ||
        normalized.toLowerCase().contains(key)) {
      return entry.value;
    }
  }

  // finally, look for any standalone 2-letter token inside the input and map it
  final twoLetterMatch = RegExp(r'\b([A-Za-z]{2})\b').firstMatch(s);
  if (twoLetterMatch != null) {
    final token = twoLetterMatch.group(1)!;
    final code = token.toLowerCase();
    if (codeMap.containsKey(code)) return _languageFlags[codeMap[code]];
    final regionFlag = countryCodeToFlag(token);
    if (regionFlag != null) return regionFlag;
  }

  return null;
}

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
              Tab(text: 'Predefined'),
              Tab(text: 'Community'),
              Tab(text: 'My Decks'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PredefinedTab(),
            _CommunityTab(),
            _MyDecksTab(),
          ],
        ),
      ),
    );
  }
}

// Predefined Tab - Browse and import predefined decks
class _PredefinedTab extends ConsumerStatefulWidget {
  const _PredefinedTab();

  @override
  ConsumerState<_PredefinedTab> createState() => _PredefinedTabState();
}

class _PredefinedTabState extends ConsumerState<_PredefinedTab> {
  final _searchController = TextEditingController();
  String _selectedLanguage = 'All';
  String _selectedDifficulty = 'All';
  String? _importingDeckName;
  List<Map<String, dynamic>>? _predefinedDecks;
  bool _isLoadingManifest = true;

  @override
  void initState() {
    super.initState();
    _loadManifest();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _loadManifest() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final loader = PredefinedDecksLoader(userId: userId);
      final manifest = await loader.loadManifestWithCardCounts();
      if (mounted) {
        setState(() {
          _predefinedDecks = manifest;
          _isLoadingManifest = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingManifest = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get unique languages from manifest for the filter
  List<String> get _availableLanguages {
    if (_predefinedDecks == null) return ['All'];
    final languages = <String>{};
    for (final deck in _predefinedDecks!) {
      final front = deck['frontLanguageName'] as String?;
      final back = deck['backLanguageName'] as String?;
      if (front != null) languages.add(front);
      if (back != null) languages.add(back);
    }
    return ['All', ...languages.toList()..sort()];
  }

  /// Filter decks based on search, language, and difficulty
  List<Map<String, dynamic>> get _filteredDecks {
    if (_predefinedDecks == null) return [];
    return _predefinedDecks!.where((deck) {
      // Search filter
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        final name = (deck['name'] as String? ?? '').toLowerCase();
        final desc = (deck['description'] as String? ?? '').toLowerCase();
        final front =
            (deck['frontLanguageName'] as String? ?? '').toLowerCase();
        final back = (deck['backLanguageName'] as String? ?? '').toLowerCase();
        if (!name.contains(query) &&
            !desc.contains(query) &&
            !front.contains(query) &&
            !back.contains(query)) {
          return false;
        }
      }
      // Language filter
      if (_selectedLanguage != 'All') {
        final front = deck['frontLanguageName'] as String? ?? '';
        final back = deck['backLanguageName'] as String? ?? '';
        if (front != _selectedLanguage && back != _selectedLanguage) {
          return false;
        }
      }
      // Difficulty filter
      if (_selectedDifficulty != 'All') {
        final diff = deck['difficulty'] as String? ?? '';
        if (diff != _selectedDifficulty.toLowerCase()) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search decks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // Filter row: Language + Difficulty
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _LanguageFilterDropdown(
                  value: _selectedLanguage,
                  items: _availableLanguages,
                  onChanged: (v) => setState(() => _selectedLanguage = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DifficultyFilterDropdown(
                  value: _selectedDifficulty,
                  onChanged: (v) => setState(() => _selectedDifficulty = v),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Active filter chips
        if (_selectedLanguage != 'All' || _selectedDifficulty != 'All')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_selectedLanguage != 'All')
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: Text(
                        _languageFlags[_selectedLanguage] ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                      label: Text(
                        _selectedLanguage,
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          setState(() => _selectedLanguage = 'All'),
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (_selectedDifficulty != 'All')
                  Chip(
                    label: Text(
                      _selectedDifficulty,
                      style: TextStyle(
                        fontSize: 12,
                        color: _difficultyColor(
                          _selectedDifficulty.toLowerCase(),
                        ),
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () =>
                        setState(() => _selectedDifficulty = 'All'),
                    backgroundColor:
                        _difficultyColor(_selectedDifficulty.toLowerCase())
                            .withValues(alpha: 0.1),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

        const SizedBox(height: 4),

        // Deck list
        Expanded(
          child: _isLoadingManifest
              ? const Center(child: CircularProgressIndicator())
              : _filteredDecks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 56,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No decks match your filters',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: _filteredDecks.length,
                      itemBuilder: (context, index) {
                        final d = _filteredDecks[index];
                        final name = d['name'] as String? ?? '';
                        return MarketplaceDeckCard(
                          deck: d,
                          isImporting: _importingDeckName == name,
                          onImport: () => _importPredefinedDeck(name),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Color _difficultyColor(String difficulty) {
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

  Future<void> _importPredefinedDeck(String deckName) async {
    setState(() {
      _importingDeckName = deckName;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check for duplicate deck (by name + predefined flag)
      final decksCol = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('decks');

      final duplicateCheck = await decksCol
          .where('name', isEqualTo: deckName)
          .where('isPredefined', isEqualTo: true)
          .limit(1)
          .get();

      if (duplicateCheck.docs.isNotEmpty) {
        if (mounted) {
          setState(() => _importingDeckName = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('"$deckName" is already in your decks'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final loader = PredefinedDecksLoader(userId: userId);
      final deckId = await loader.importPredefinedDeck(deckName);

      if (deckId != null && mounted) {
        // Refresh the deck list so the imported deck appears in My Decks
        ref.read(deckListProvider.notifier).loadDecks();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('$deckName imported successfully!')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
          _importingDeckName = null;
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Reusable filter widgets
// ---------------------------------------------------------------------------

/// Language filter dropdown with flag emojis
class _LanguageFilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _LanguageFilterDropdown({
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
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          isDense: true,
          isExpanded: true,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          items: items.map((lang) {
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
                  Text(
                    lang,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight:
                          lang == value ? FontWeight.w600 : FontWeight.normal,
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

/// Difficulty filter dropdown with per-item colors
class _DifficultyFilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _DifficultyFilterDropdown({
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

/// Difficulty badge shown on deck cards
class _DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const _DifficultyBadge({required this.difficulty});

  Color get _color {
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

  @override
  Widget build(BuildContext context) {
    final label = difficulty[0].toUpperCase() + difficulty.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.signal_cellular_alt, size: 12, color: _color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class MarketplaceDeckCard extends StatelessWidget {
  final Map<String, dynamic> deck;
  final bool showAuthorRow;
  final String? authorName;
  final int? downloads;
  final bool isImporting;
  final VoidCallback? onImport;
  final bool
      isCommunity; // when true, details dialog shows only author + downloads
  final Widget?
      trailingAction; // optional override for action column (e.g. Unpublish button)
  final bool
      centerAction; // when true, place `trailingAction` centered below content

  const MarketplaceDeckCard({
    super.key,
    required this.deck,
    this.showAuthorRow = false,
    this.authorName,
    this.downloads,
    this.isImporting = false,
    this.onImport,
    this.isCommunity = false,
    this.trailingAction,
    this.centerAction = false,
  });

  String _shortenNumber(int? n) {
    if (n == null) return '0';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = deck['name'] as String? ?? 'Untitled';
    final description = deck['description'] as String? ?? '';
    final difficulty = deck['difficulty'] as String? ?? '';

    // collect possible flags (support various field names and fallbacks)
    String? resolveFlag(String? explicit, String? langName) {
      if (explicit != null && explicit.isNotEmpty) return explicit;
      return _flagForLanguageName(langName);
    }

    final rawFlags = <String?>[
      resolveFlag(
        deck['frontFlag'] as String?,
        deck['frontLanguageName'] as String?,
      ),
      resolveFlag(
        deck['middleFlag'] as String?,
        deck['middleLanguageName'] as String?,
      ),
      resolveFlag(
        deck['backFlag'] as String?,
        deck['backLanguageName'] as String?,
      ),
      resolveFlag(
        deck['thirdFlag'] as String?,
        deck['thirdLanguageName'] as String?,
      ),
    ];

    // dedupe while preserving order and remove null/empty
    final seen = <String>{};
    final flags = <String>[];
    for (final f in rawFlags) {
      if (f == null || f.isEmpty) continue;
      if (seen.contains(f)) continue;
      seen.add(f);
      flags.add(f);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // icon (manifest may include emoji string) — fallback to 📚
                          Text(
                            (deck['icon'] as String?) ?? '📚',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      if (description.isNotEmpty ||
                          (isCommunity &&
                              (authorName != null && authorName!.isNotEmpty)))
                        Text(
                          // append author for community decks: "by author_name"
                          (() {
                            final desc = description;
                            if (isCommunity &&
                                authorName != null &&
                                authorName!.isNotEmpty) {
                              if (desc.isEmpty) return 'by ${authorName!}';
                              return '$desc • by ${authorName!}';
                            }
                            return desc;
                          })(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 8),

                      // Difficulty → card-count → downloads badge
                      Row(
                        children: [
                          if (difficulty.isNotEmpty) ...[
                            _DifficultyBadge(difficulty: difficulty),
                            const SizedBox(width: 6),
                          ],

                          if (deck['cardCount'] != null) ...[
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
                                '${deck['cardCount']} cards',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // Flags: show up to 3 inline flags (no horizontal scroll).
                          // If there are more than 3, show a small "+N" indicator.
                          if (flags.isNotEmpty)
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  for (final f in flags.take(3))
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        f,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  if (flags.length > 3)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '+${flags.length - 3}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Author & download counts are intentionally moved into the Details dialog per request.
                    ],
                  ),
                ),

                if (centerAction && trailingAction != null) ...[
                  // Place the provided action at the top-right and let it size itself
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: trailingAction!,
                    ),
                  ),
                ],

                if (!centerAction) ...[
                  const SizedBox(width: 8),

                  // Action column: import button (when provided) or options menu
                  trailingAction ??
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: isImporting
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : (onImport != null
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.download_rounded,
                                          color: colorScheme.primary,
                                        ),
                                        onPressed: onImport,
                                        tooltip: 'Import deck',
                                      )
                                    : PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        onSelected: (value) async {
                                          if (value == 'view') {
                                            await showDialog<void>(
                                              context: context,
                                              builder: (ctx) {
                                                return AlertDialog(
                                                  title: Row(
                                                    children: [
                                                      Text(
                                                        (deck['icon']
                                                                as String?) ??
                                                            '📚',
                                                        style: const TextStyle(
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: theme.textTheme
                                                              .titleMedium,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  content:
                                                      SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (description
                                                            .isNotEmpty)
                                                          Text(description),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        if (!isCommunity)
                                                          Row(
                                                            children: [
                                                              if (difficulty
                                                                  .isNotEmpty)
                                                                _DifficultyBadge(
                                                                  difficulty:
                                                                      difficulty,
                                                                ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              if (deck[
                                                                      'cardCount'] !=
                                                                  null)
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .blue
                                                                        .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                      8,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    '${deck['cardCount']} cards',
                                                                    style: theme
                                                                        .textTheme
                                                                        .labelSmall
                                                                        ?.copyWith(
                                                                      color: Colors
                                                                          .blue
                                                                          .shade700,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ),
                                                                ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              for (final f
                                                                  in flags)
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                    right: 6,
                                                                  ),
                                                                  child: Text(
                                                                    f,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          18,
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        // Community decks: show author + downloads only (handled later)
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        if (authorName != null)
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .person_outline,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  authorName!,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        if (downloads !=
                                                            null) ...[
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .download_rounded,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                '${_shortenNumber(downloads)} downloads',
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        if (!isCommunity) ...[
                                                          if (deck[
                                                                  'category'] !=
                                                              null) ...[
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .label_outline,
                                                                  size: 16,
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  '${deck['category']}',
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          Wrap(
                                                            spacing: 8,
                                                            runSpacing: 6,
                                                            children: [
                                                              if (deck[
                                                                      'frontLanguageName'] !=
                                                                  null)
                                                                Chip(
                                                                  label: Text(
                                                                    deck['frontLanguageName']
                                                                        as String,
                                                                  ),
                                                                ),
                                                              if (deck[
                                                                      'middleLanguageName'] !=
                                                                  null)
                                                                Chip(
                                                                  label: Text(
                                                                    deck['middleLanguageName']
                                                                        as String,
                                                                  ),
                                                                ),
                                                              if (deck[
                                                                      'backLanguageName'] !=
                                                                  null)
                                                                Chip(
                                                                  label: Text(
                                                                    deck['backLanguageName']
                                                                        as String,
                                                                  ),
                                                                ),
                                                              if (deck[
                                                                      'thirdLanguageName'] !=
                                                                  null)
                                                                Chip(
                                                                  label: Text(
                                                                    deck['thirdLanguageName']
                                                                        as String,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(ctx),
                                                      child:
                                                          const Text('Close'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(ctx);
                                                        if (onImport != null) {
                                                          onImport!();
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Download not available for this deck',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: const Text(
                                                        'Download',
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else if (value == 'report') {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text('Reported'),
                                              ),
                                            );
                                          }
                                        },
                                        itemBuilder: (ctx) => const [
                                          PopupMenuItem(
                                            value: 'view',
                                            child: Text('View details'),
                                          ),
                                          PopupMenuItem(
                                            value: 'report',
                                            child: Text('Report'),
                                          ),
                                        ],
                                      )),
                          ),
                        ],
                      ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityTab extends ConsumerStatefulWidget {
  const _CommunityTab();

  @override
  ConsumerState<_CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends ConsumerState<_CommunityTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLanguage = 'All';
  String _selectedDifficulty = 'All';
  String? _importingDeckName; // show progress when importing a community deck

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() {
        _searchQuery = _searchController.text;
      }),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> decks,
    String language,
    String difficulty,
    String query,
  ) {
    var filtered = decks;

    // search
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((d) {
        final name = (d['name'] as String? ?? '').toLowerCase();
        final desc = (d['description'] as String? ?? '').toLowerCase();
        final author = (d['authorName'] as String? ?? '').toLowerCase();
        return name.contains(q) || desc.contains(q) || author.contains(q);
      }).toList();
    }

    // language
    if (language != 'All') {
      filtered = filtered.where((d) {
        final front = (d['frontLanguageName'] as String? ?? '').toLowerCase();
        final back = (d['backLanguageName'] as String? ?? '').toLowerCase();
        return front == language.toLowerCase() ||
            back == language.toLowerCase();
      }).toList();
    }

    // difficulty
    if (difficulty != 'All') {
      filtered = filtered.where((d) {
        final diff = (d['difficulty'] as String? ?? '').toLowerCase();
        return diff == difficulty.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  Future<void> _importCommunityDeck(Map<String, dynamic> data) async {
    final deckName = data['name'] as String? ?? 'Untitled';
    setState(() => _importingDeckName = deckName);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final authorId = data['authorId'] as String?;
      final originalDeckId = data['originalDeckId'] as String?;
      final sourceId = (authorId != null && originalDeckId != null)
          ? '\$authorId_\$originalDeckId'
          : null;

      final decksCol = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('decks');

      // duplicate check by sourceId or name
      if (sourceId != null) {
        final dup = await decksCol
            .where('sourceId', isEqualTo: sourceId)
            .limit(1)
            .get();
        if (dup.docs.isNotEmpty) {
          if (mounted) {
            setState(() => _importingDeckName = null);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"$deckName" is already in your decks')),
            );
          }
          return;
        }
      } else {
        final dup =
            await decksCol.where('name', isEqualTo: deckName).limit(1).get();
        if (dup.docs.isNotEmpty) {
          if (mounted) {
            setState(() => _importingDeckName = null);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"$deckName" is already in your decks')),
            );
          }
          return;
        }
      }

      // create new deck document for current user
      final now = DateTime.now();
      final newDocRef = decksCol.doc();
      final newDeckData = {
        'id': newDocRef.id,
        'name': deckName,
        'description': data['description'] as String? ?? '',
        'parentId': null,
        'tags': data['tags'] ?? [],
        'color': 'blue',
        'icon': data['icon'] as String? ?? '📚',
        'frontEmoji': data['frontFlag'] as String?,
        'backEmoji': data['backFlag'] as String?,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'cardCount': 0,
        'newCardCount': 0,
        'dueCardCount': 0,
        'dailyNewCardLimit': 20,
        'dailyReviewLimit': 100,
        'shuffleCards': true,
        'isStarred': false,
        'isPublished': false,
        'frontLanguageName': data['frontLanguageName'],
        'backLanguageName': data['backLanguageName'],
        'sourceId': sourceId,
        'category': data['category'],
        'difficulty': data['difficulty'],
        'authorId': data['authorId'],
        'authorName': data['authorName'],
        'isPredefined': false,
      };

      await newDocRef.set(newDeckData);

      // try to copy cards from publisher's deck (if accessible)
      int copied = 0;
      if (authorId != null && originalDeckId != null) {
        final cardsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(authorId)
            .collection('decks')
            .doc(originalDeckId)
            .collection('cards')
            .get();
        if (cardsSnap.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (final c in cardsSnap.docs) {
            final cardData = Map<String, dynamic>.from(c.data());
            cardData.remove('id');
            cardData['deckId'] = newDocRef.id;
            final newCardRef = FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('decks')
                .doc(newDocRef.id)
                .collection('cards')
                .doc();
            batch.set(newCardRef, cardData);
            copied++;
          }
          await batch.commit();
          await newDocRef.update({
            'cardCount': copied,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }

      // increment community downloads counter when possible
      if (authorId != null && originalDeckId != null) {
        const communityDocId = '\$authorId_\$originalDeckId';
        final communityRef = FirebaseFirestore.instance
            .collection('community_decks')
            .doc(communityDocId);
        await communityRef.update({'downloads': FieldValue.increment(1)});
      }

      // refresh local deck list and show success
      ref.read(deckListProvider.notifier).loadDecks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deckName imported ($copied cards)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing deck: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importingDeckName = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('community_decks')
          .orderBy('publishedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final rawDocs = snapshot.data?.docs ?? [];
        // exclude 'english arabic' from community listing
        final docs = rawDocs.where((d) {
          final name = (d.data()['name'] as String?)?.toLowerCase() ?? '';
          // exclude any community deck whose name references "english" and "arabic"
          if (name.contains('english') && name.contains('arabic')) return false;
          return true;
        }).toList();
        final decks = docs.map((d) => d.data()).toList();

        // compute available languages from docs
        final langs = <String>{};
        for (final d in decks) {
          final front = d['frontLanguageName'] as String?;
          final back = d['backLanguageName'] as String?;
          if (front != null && front.isNotEmpty) langs.add(front);
          if (back != null && back.isNotEmpty) langs.add(back);
        }
        final availableLanguages = ['All', ...langs.toList()..sort()];

        // filter decks
        final filtered = _applyFilters(
          decks,
          _selectedLanguage,
          _selectedDifficulty,
          _searchQuery,
        );

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search decks...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ),

            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _LanguageFilterDropdown(
                      value: _selectedLanguage,
                      items: availableLanguages,
                      onChanged: (v) => setState(() => _selectedLanguage = v),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DifficultyFilterDropdown(
                      value: _selectedDifficulty,
                      onChanged: (v) => setState(() => _selectedDifficulty = v),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Deck list or empty state
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 56,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No decks match your filters',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final data = filtered[index];

                        // map language names -> flags for marketplace card
                        var front = data['frontLanguageName'] as String?;
                        var back = data['backLanguageName'] as String?;

                        // support older/alternate document shapes like a single `languageName` string
                        if (front == null && data['languageName'] != null) {
                          final lang = data['languageName'] as String;
                          final parts = lang.split(RegExp(r'[ ,;/]+'));
                          front = parts.isNotEmpty ? parts[0] : null;
                          if (parts.length > 1) back = parts[1];
                        }

                        // support an array field `languages: ['English','French']`
                        if ((front == null || front.isEmpty) &&
                            data['languages'] is List &&
                            (data['languages'] as List).isNotEmpty) {
                          final langs = List.from(data['languages'] as List);
                          front =
                              langs.isNotEmpty ? langs[0] as String? : front;
                          if (langs.length > 1) back = langs[1] as String?;
                        }

                        String? third;
                        if (data['thirdFlag'] != null) {
                          third = data['thirdFlag'] as String?;
                        } else if (data['thirdLanguageName'] != null) {
                          third = _flagForLanguageName(
                            data['thirdLanguageName'] as String?,
                          );
                        } else if (data['middleLanguageName'] != null) {
                          third = _flagForLanguageName(
                            data['middleLanguageName'] as String?,
                          );
                        } else if (data['languages'] is List &&
                            (data['languages'] as List).length > 2) {
                          third = _flagForLanguageName(
                            (data['languages'] as List)[2] as String?,
                          );
                        }

                        final deckMap = <String, dynamic>{
                          'name': data['name'],
                          'description': data['description'],
                          'icon': data['icon'],
                          'cardCount': data['cardCount'],
                          'difficulty': data['difficulty'],
                          // prefer an explicit flag field from the document; otherwise map language name → flag
                          'frontFlag': (data['frontFlag'] as String?) ??
                              _flagForLanguageName(front),
                          'backFlag': (data['backFlag'] as String?) ??
                              _flagForLanguageName(back),
                          'thirdFlag': (data['thirdFlag'] as String?) ??
                              _flagForLanguageName(third),

                          // keep original language names for fallback
                          'frontLanguageName': front,
                          'backLanguageName': back,
                        };

                        // derive a reliable authorName (fall back to current user's display name when appropriate)
                        String? authorName =
                            (data['authorName'] as String?)?.trim();
                        final authorId = data['authorId'] as String?;
                        final currentUid =
                            FirebaseAuth.instance.currentUser?.uid;
                        if ((authorName == null || authorName.isEmpty) &&
                            authorId != null &&
                            authorId == currentUid) {
                          authorName =
                              FirebaseAuth.instance.currentUser?.displayName ??
                                  FirebaseAuth.instance.currentUser?.email
                                      ?.split('@')
                                      .first;
                        }

                        return MarketplaceDeckCard(
                          deck: deckMap,
                          showAuthorRow: true,
                          isCommunity: true,
                          authorName: authorName,
                          downloads: ((data['downloads'] as int?) ??
                                  (data['downloadCount'] as int?)) ??
                              0,
                          isImporting:
                              _importingDeckName == (data['name'] as String?),
                          onImport: () => _importCommunityDeck(data),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// My Decks Tab – shows user's published decks with unpublish option
// ---------------------------------------------------------------------------

class _MyDecksTab extends ConsumerWidget {
  const _MyDecksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch the deck list provider (async). `decksAsync` is an AsyncValue —
    // handled below with `.when(data/loading/error)`. Use this provider to
    // read/update decks via its notifier (see `publishDeck` calls later).
    final decksAsync = ref.watch(deckListProvider);

    return decksAsync.when(
      data: (allDecks) {
        // `allDecks` contains the user's decks from the provider. For the
        // "My Decks" tab we only display decks where `isPublished == true`.
        final published = allDecks.where((d) => d.isPublished).toList();
        if (published.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.publish_outlined,
                    size: 80,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Published Decks',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publish your decks from the My Decks screen\nto see them here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: published.length,
          itemBuilder: (context, index) {
            final deck = published[index];

            // Build a lightweight map with the display fields the card expects.
            // If you need the deck `id` inside the card, add `'id': deck.id` here.
            final deckMap = <String, dynamic>{
              'name': deck.name,
              'description': deck.description,
              'icon': deck.icon,
              'cardCount': deck.cardCount,
              'difficulty': deck.difficulty,
              'frontFlag': deck.frontEmoji,
              'backFlag': deck.backEmoji,
            };

            // --- Unpublish UX (two entry points) ---
            // 1) Swipe left on the card (Dismissible) — immediate unpublish + Undo
            // 2) Tap the compact red trash icon (trailingAction) — same behavior
            // Both call `publishDeck(deck.id, false)` on the provider notifier.
            return Dismissible(
              key: ValueKey(deck.id),
              direction: DismissDirection.endToStart,
              // Center the trash icon in the swipe background so it visually
              // matches the centered action button displayed on the card.
              background: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.red),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              onDismissed: (direction) async {
                // Quick unpublish: set published -> false, then offer Undo.
                await ref
                    .read(deckListProvider.notifier)
                    .publishDeck(deck.id, false);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('\${deck.name} unpublished'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          await ref
                              .read(deckListProvider.notifier)
                              .publishDeck(deck.id, true);
                        },
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MarketplaceDeckCard(
                  deck: deckMap,
                  showAuthorRow: false,
                  authorName: null,
                  downloads: 0,
                  isImporting: false,
                  onImport: null,

                  // Show the unpublish action aligned to top-right and compact.
                  centerAction: true,
                  trailingAction: IconButton(
                    tooltip: 'Unpublish',
                    // shrink to the icon only
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 24,
                    ),
                    onPressed: () async {
                      // quick unpublish (no confirm) + Undo
                      await ref
                          .read(deckListProvider.notifier)
                          .publishDeck(deck.id, false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${deck.name} unpublished'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () async {
                                await ref
                                    .read(deckListProvider.notifier)
                                    .publishDeck(deck.id, true);
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

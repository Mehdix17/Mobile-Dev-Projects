import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../../data/models/deck_model.dart';
import '../providers/deck_provider.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

class DeckEditorScreen extends ConsumerStatefulWidget {
  final String? deckId;

  const DeckEditorScreen({super.key, this.deckId});

  @override
  ConsumerState<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends ConsumerState<DeckEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedIcon = '📚';
  String? _frontLanguage;
  String? _backLanguage;
  String? _selectedDifficulty;
  bool _isLoading = false;
  DeckModel? _existingDeck;

  // Language to flag emoji mapping
  static const Map<String, String> _languageFlags = {
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

  @override
  void initState() {
    super.initState();
    if (widget.deckId != null) {
      _loadDeck();
    }
  }

  Future<void> _loadDeck() async {
    final deck = await ref.read(deckRepositoryProvider).getDeck(widget.deckId!);
    if (deck != null && mounted) {
      setState(() {
        _existingDeck = deck;
        _nameController.text = deck.name;
        _descriptionController.text = deck.description;
        _selectedIcon = deck.icon;
        // Find language from emoji
        _frontLanguage = deck.frontEmoji != null
            ? _languageFlags.entries
                .firstWhere(
                  (e) => e.value == deck.frontEmoji,
                  orElse: () => const MapEntry('', ''),
                )
                .key
            : null;
        _backLanguage = deck.backEmoji != null
            ? _languageFlags.entries
                .firstWhere(
                  (e) => e.value == deck.backEmoji,
                  orElse: () => const MapEntry('', ''),
                )
                .key
            : null;
        if (_frontLanguage?.isEmpty == true) _frontLanguage = null;
        if (_backLanguage?.isEmpty == true) _backLanguage = null;
        _selectedDifficulty = deck.difficulty;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.deckId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Deck' : 'New Deck'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDeck,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // show preview only when editing an existing deck — for New Deck the name field should be first
            if (isEditing) ...[
              _buildPreviewCard(theme),
              const SizedBox(height: 24),
            ],

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Deck Name',
                hintText: 'e.g., Essential Vocabulary',
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              enableSuggestions: true,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a deck name';
                }
                if (value.length > 50) {
                  return 'Name must be 50 characters or less';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this deck about?',
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enableSuggestions: true,
              autocorrect: true,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Icon selector
            Text(
              'Icon',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showEmojiPicker(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedIcon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap to select emoji',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Card languages section
            Text(
              'Card Languages (optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select languages to show country flags on cards',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageDropdown(
                    theme,
                    'Front Card Language',
                    _frontLanguage,
                    (language) => setState(() => _frontLanguage = language),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLanguageDropdown(
                    theme,
                    'Back Card Language',
                    _backLanguage,
                    (language) => setState(() => _backLanguage = language),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Difficulty selector
            Text(
              'Difficulty (optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _selectedDifficulty,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('None', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 'beginner',
                  child: Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt_1_bar,
                        size: 18,
                        color: Colors.green,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Beginner',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'intermediate',
                  child: Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt_2_bar,
                        size: 18,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Intermediate',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'advanced',
                  child: Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Advanced',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedDifficulty = value);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final name =
        _nameController.text.isEmpty ? 'Deck Name' : _nameController.text;
    final bool editing = _existingDeck != null;

    if (editing) {
      final color = Color(_existingDeck!.color.colorValue);
      return Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.8), color],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_selectedIcon, style: const TextStyle(fontSize: 32)),
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    // New deck — neutral preview (no selectable color)
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_selectedIcon, style: const TextStyle(fontSize: 32)),
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDeck() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      if (_existingDeck != null) {
        // Update existing deck
        final updated = _existingDeck!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          frontEmoji:
              _frontLanguage != null ? _languageFlags[_frontLanguage] : null,
          backEmoji:
              _backLanguage != null ? _languageFlags[_backLanguage] : null,
          difficulty: _selectedDifficulty,
          updatedAt: now,
        );
        await ref.read(deckListProvider.notifier).updateDeck(updated);
      } else {
        // Create new deck
        final deck = DeckModel.create(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          frontEmoji:
              _frontLanguage != null ? _languageFlags[_frontLanguage] : null,
          backEmoji:
              _backLanguage != null ? _languageFlags[_backLanguage] : null,
          difficulty: _selectedDifficulty,
        );
        await ref.read(deckListProvider.notifier).createDeck(deck);
      }

      if (mounted) {
        context.showSuccessSnackBar(
          _existingDeck != null ? 'Deck updated!' : 'Deck created!',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error saving deck: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 300,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            setState(() => _selectedIcon = emoji.emoji);
            Navigator.pop(ctx);
          },
          config: const Config(
            emojiViewConfig: EmojiViewConfig(
              columns: 7,
              emojiSizeMax: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(
    ThemeData theme,
    String label,
    String? selectedLanguage,
    void Function(String?) onSelect,
  ) {
    final sortedLanguages = _languageFlags.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedLanguage,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          hint: const Text('Select language'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('None')),
            ...sortedLanguages.map((language) {
              return DropdownMenuItem<String>(
                value: language,
                child: Row(
                  children: [
                    // flag emoji — slightly smaller to save horizontal space
                    Text(_languageFlags[language]!,
                        style: const TextStyle(fontSize: 18),),
                    const SizedBox(width: 8),

                    // Make the language label flexible and ellipsize long names
                    Expanded(
                      child: Text(
                        language,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: onSelect,
        ),
      ],
    );
  }
}

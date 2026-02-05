import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../data/models/card_model.dart';
import '../providers/card_provider.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/constants/predefined_tags.dart';

class CardEditorScreen extends ConsumerStatefulWidget {
  final String deckId;
  final String? cardId;

  const CardEditorScreen({
    super.key,
    required this.deckId,
    this.cardId,
  });

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  CardType _selectedType = CardType.basic;
  bool _isLoading = false;
  CardModel? _existingCard;
  String? _selectedImagePath;

  // Controllers for different field types
  final Map<String, TextEditingController> _controllers = {};
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.cardId != null) {
      _loadCard();
    }
  }

  void _initControllers() {
    // Initialize controllers for all possible fields
    final allFields = [
      'front',
      'back',
      'word',
      'imageUrl',
      'scrambled',
      'correct',
      'face1',
      'face2',
      'face3',
      'frontHint',
      'backHint',
    ];
    for (final field in allFields) {
      _controllers[field] = TextEditingController();
    }
  }

  Future<void> _loadCard() async {
    final card = await ref
        .read(cardRepositoryProvider)
        .getCard(widget.deckId, widget.cardId!);
    if (card != null && mounted) {
      setState(() {
        _existingCard = card;
        _selectedType = card.type;
        _tags = List.from(card.tags);

        // Populate controllers with existing data
        final fields = card.fields;
        for (final entry in fields.entries) {
          if (_controllers.containsKey(entry.key)) {
            _controllers[entry.key]!.text = entry.value?.toString() ?? '';
          }
        }

        // Load hints separately (they're stored as direct properties, not in fields)
        if (card.frontHint != null && card.frontHint!.isNotEmpty) {
          _controllers['frontHint']?.text = card.frontHint!;
        }
        if (card.backHint != null && card.backHint!.isNotEmpty) {
          _controllers['backHint']?.text = card.backHint!;
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.cardId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Card' : 'New Card'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCard,
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
            // Card type selector (only for new cards)
            if (!isEditing) ...[
              Text(
                'Card Type',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: CardType.values.map((type) {
                    final isSelected = type == _selectedType;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(type.icon),
                            const SizedBox(width: 4),
                            Text(type.displayName),
                          ],
                        ),
                        selected: isSelected,
                        selectedColor:
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedType = type);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedType.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Dynamic fields based on card type
            ..._buildFieldsForType(),

            const SizedBox(height: 16),

            // Tags
            Text(
              'Tags (optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: PredefinedTags.tags.map((predefinedTag) {
                final isSelected = _tags.contains(predefinedTag.name);
                return FilterChip(
                  label: Text(
                    predefinedTag.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : predefinedTag.color,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _tags.add(predefinedTag.name);
                      } else {
                        _tags.remove(predefinedTag.name);
                      }
                    });
                  },
                  backgroundColor: predefinedTag.color.withValues(alpha: 0.1),
                  selectedColor: predefinedTag.color,
                  showCheckmark: false,
                  side: BorderSide(
                    color: predefinedTag.color,
                    width: 1.5,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldsForType() {
    final widgets = <Widget>[];

    switch (_selectedType) {
      case CardType.basic:
        widgets.addAll([
          _buildTextField('front', 'Front', required: true, maxLines: 2),
          const SizedBox(height: 16),
          _buildTextField('back', 'Back', required: true, maxLines: 2),
          const SizedBox(height: 16),
          _buildTextField('frontHint', 'Front Hint (optional)'),
          const SizedBox(height: 16),
          _buildTextField('backHint', 'Back Hint (optional)'),
        ]);
        break;

      case CardType.wordImage:
        widgets.addAll([
          _buildImagePicker(),
          const SizedBox(height: 16),
          _buildTextField('word', 'Text', required: true),
          const SizedBox(height: 16),
          _buildTextField('frontHint', 'Hint (optional)'),
        ]);
        break;

      case CardType.threeFaces:
        widgets.addAll([
          _buildTextField('face1', 'Face 1 (e.g., English)', required: true),
          const SizedBox(height: 16),
          _buildTextField('face2', 'Face 2 (e.g., French)', required: true),
          const SizedBox(height: 16),
          _buildTextField('face3', 'Face 3 (e.g., Arabic)', required: true),
          const SizedBox(height: 16),
          _buildTextField('frontHint', 'Hint (optional)'),
        ]);
        break;
    }

    return widgets;
  }

  Widget _buildTextField(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
      ),
      maxLines: maxLines,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      enableSuggestions: true,
      autocorrect: true,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Build fields map (excluding hints - they're stored separately)
      final fields = <String, dynamic>{};
      final requiredFields = _selectedType.requiredFields;

      for (final field in requiredFields) {
        final value = _controllers[field]?.text.trim();
        if (value != null && value.isNotEmpty) {
          fields[field] = value;
        }
      }

      // Get hints separately (they're stored as direct properties, not in fields)
      final frontHint = _controllers['frontHint']?.text.trim();
      final backHint = _controllers['backHint']?.text.trim();

      if (_existingCard != null) {
        // Update existing card
        final updated = _existingCard!.copyWith(
          fields: fields,
          frontHint: frontHint?.isNotEmpty == true ? frontHint : null,
          backHint: backHint?.isNotEmpty == true ? backHint : null,
          tags: _tags,
          updatedAt: DateTime.now(),
        );
        await ref
            .read(cardListProvider(widget.deckId).notifier)
            .updateCard(updated);
      } else {
        // Create new card with hints as separate properties
        final now = DateTime.now();
        final card = CardModel(
          id: '',
          deckId: widget.deckId,
          type: _selectedType,
          fields: fields,
          tags: _tags,
          frontHint: frontHint?.isNotEmpty == true ? frontHint : null,
          backHint: backHint?.isNotEmpty == true ? backHint : null,
          createdAt: now,
          updatedAt: now,
        );
        await ref
            .read(cardListProvider(widget.deckId).notifier)
            .createCard(card);
      }

      if (mounted) {
        context.showSuccessSnackBar(
          _existingCard != null ? 'Card updated!' : 'Card created!',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error saving card: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image *',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
              allowMultiple: false,
            );
            if (result != null && result.files.single.path != null) {
              setState(() {
                _selectedImagePath = result.files.single.path;
                _controllers['imageUrl']!.text = _selectedImagePath!;
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedImagePath != null
                        ? 'Image selected: ${_selectedImagePath!.split('/').last}'
                        : (_controllers['imageUrl']?.text.isNotEmpty == true
                            ? 'Image: ${_controllers['imageUrl']!.text.split('/').last}'
                            : 'Select image from device'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        if (_selectedImagePath != null ||
            _controllers['imageUrl']?.text.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedImagePath ?? _controllers['imageUrl']!.text),
                height: 250,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Could not load image',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

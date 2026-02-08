import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../decks/data/models/deck_model.dart';
import '../../../decks/data/repositories/deck_repository.dart';
import '../../../cards/data/models/card_model.dart';
import '../../../cards/data/repositories/card_repository.dart';
import '../../../decks/presentation/providers/deck_provider.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  String _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Cards'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import cards from various formats',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add flashcards to your collection by importing from files',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _ImportOptionCard(
                  icon: Icons.table_chart,
                  title: 'Import from CSV',
                  description:
                      'Import cards from CSV file. Supports basic, image, and triple cards with hints',
                  onTap: _isLoading ? null : () => _importFromCsv(),
                ),
                const SizedBox(height: 24),
                if (_statusMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                _buildCsvFormatHelp(theme),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCsvFormatHelp(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'CSV Format Guide',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Supported card types:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Basic cards
            Text(
              '✏️ Basic: front,back,frontHint,backHint',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),

            // Image cards
            Text(
              '🖼️ Image: imageUrl,word,frontHint,backHint',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),

            // Triple cards
            Text(
              '🔺 Triple: face1,face2,face3,frontHint',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),

            Text(
              '• Headers are auto-detected\n'
              '• Hints are optional\n'
              '• Card type detected from columns\n'
              '• Use quotes for text with commas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() {
        _isLoading = true;
        _statusMessage = 'Reading file...';
      });

      final file = File(result.files.single.path!);
      final contents = await file.readAsString();

      await _parseAndImportCsv(contents, result.files.single.name);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
      if (mounted) {
        context.showErrorSnackBar('Failed to import: $e');
      }
    }
  }

  Future<void> _parseAndImportCsv(String contents, String fileName) async {
    setState(() {
      _statusMessage = 'Parsing CSV...';
    });

    // Only comma delimiter is supported
    const converter = CsvToListConverter(
      fieldDelimiter: ',',
      eol: '\n',
      shouldParseNumbers: false,
    );

    List<List<dynamic>> rows;
    try {
      rows = converter.convert(contents);
    } catch (e) {
      // Try with different line endings
      rows = converter
          .convert(contents.replaceAll('\r\n', '\n').replaceAll('\r', '\n'));
    }

    if (rows.isEmpty) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'No data found in file';
      });
      return;
    }

    // Detect card type and headers from first row
    final firstRow = rows.first;
    final headers =
        firstRow.map((col) => col.toString().toLowerCase().trim()).toList();

    CardType detectedType = CardType.basic;
    int startIndex = 0;
    Map<String, int> columnMap = {};

    // Check if first row is a header by looking for known column names
    if (_isHeaderRow(headers)) {
      startIndex = 1;
      detectedType = _detectCardType(headers);
      columnMap = _buildColumnMap(headers, detectedType);
    } else {
      // No header - infer type from number of columns
      if (firstRow.length >= 3 && firstRow[2].toString().trim().isNotEmpty) {
        // Check if column 3 looks like a URL or text
        final thirdCol = firstRow[2].toString().trim();
        if (thirdCol.startsWith('http://') || thirdCol.startsWith('https://')) {
          detectedType = CardType.basic; // Treat as basic with hints
        } else {
          detectedType = CardType.threeFaces; // 3 columns = triple card
        }
      }
      columnMap = _buildDefaultColumnMap(detectedType);
    }

    // Filter valid rows based on card type
    final validRows = rows.sublist(startIndex).where((row) {
      return _isValidRow(row, detectedType, columnMap);
    }).toList();

    if (validRows.isEmpty) {
      setState(() {
        _isLoading = false;
        _statusMessage =
            'No valid cards found. Check format matches card type.';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Creating deck with ${validRows.length} cards...';
    });

    // Create a new deck for the imported cards
    final userId = _getUserId();
    final deckRepo = DeckRepository(userId: userId);
    final cardRepo = CardRepository(userId: userId);

    final deckName = fileName.replaceAll(
      RegExp(r'\.(csv|txt|tsv)$', caseSensitive: false),
      '',
    );
    final now = DateTime.now();

    final deck = DeckModel(
      id: '',
      name: deckName.isEmpty ? 'Imported Deck' : deckName,
      description:
          'Imported from $fileName on ${now.day}/${now.month}/${now.year}',
      color: DeckColor.teal,
      icon: _getIconForCardType(detectedType),
      createdAt: now,
      updatedAt: now,
      cardCount: validRows.length,
      newCardCount: validRows.length,
      dueCardCount: validRows.length,
    );

    await deckRepo.createDeck(deck);

    // Get the created deck to get its ID
    final allDecks = await deckRepo.getAllDecks();
    final createdDeck = allDecks.firstWhere(
      (d) => d.name == deck.name && d.description == deck.description,
      orElse: () => allDecks.first,
    );

    setState(() {
      _statusMessage = 'Adding cards to deck...';
    });

    // Create cards based on detected type
    final cards = validRows.map((row) {
      return _createCardFromRow(
          row, createdDeck.id, detectedType, columnMap, now,);
    }).toList();

    await cardRepo.batchCreateCards(cards);

    // Refresh decks
    ref.invalidate(decksProvider);
    ref.invalidate(recentDecksProvider);
    ref.invalidate(deckListProvider);

    setState(() {
      _isLoading = false;
      _statusMessage =
          'Successfully imported ${cards.length} ${detectedType.displayName} cards to "$deckName"!';
    });

    if (mounted) {
      context.showSuccessSnackBar(
          'Imported ${cards.length} ${detectedType.displayName} cards!',);
    }
  }

  bool _isHeaderRow(List<String> headers) {
    // Check for known header patterns
    final knownHeaders = [
      'front',
      'back',
      'question',
      'answer',
      'word',
      'definition',
      'imageurl',
      'image',
      'fronthint',
      'backhint',
      'hint',
      'face1',
      'face2',
      'face3',
    ];

    return headers.any((h) => knownHeaders.contains(h));
  }

  CardType _detectCardType(List<String> headers) {
    // Check for triple card
    if (headers.contains('face1') &&
        headers.contains('face2') &&
        headers.contains('face3')) {
      return CardType.threeFaces;
    }

    // Check for image card
    if (headers.contains('imageurl') || headers.contains('image')) {
      return CardType.wordImage;
    }

    // Default to basic
    return CardType.basic;
  }

  Map<String, int> _buildColumnMap(List<String> headers, CardType type) {
    final Map<String, int> map = {};

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];

      // Check for labels/tags column (works for all card types)
      if (header == 'labels' ||
          header == 'tags' ||
          header == 'label' ||
          header == 'tag') {
        map['labels'] = i;
      }

      switch (type) {
        case CardType.basic:
          if (header == 'front' || header == 'question' || header == 'word') {
            map['front'] = i;
          } else if (header == 'back' ||
              header == 'answer' ||
              header == 'definition') {
            map['back'] = i;
          } else if (header == 'fronthint') {
            map['frontHint'] = i;
          } else if (header == 'backhint') {
            map['backHint'] = i;
          }
          break;

        case CardType.wordImage:
          if (header == 'imageurl' || header == 'image') {
            map['imageUrl'] = i;
          } else if (header == 'word' ||
              header == 'text' ||
              header == 'answer') {
            map['word'] = i;
          } else if (header == 'fronthint') {
            map['frontHint'] = i;
          } else if (header == 'backhint') {
            map['backHint'] = i;
          }
          break;

        case CardType.threeFaces:
          if (header == 'face1') {
            map['face1'] = i;
          } else if (header == 'face2') {
            map['face2'] = i;
          } else if (header == 'face3') {
            map['face3'] = i;
          } else if (header == 'fronthint' || header == 'hint') {
            map['frontHint'] = i;
          }
          break;
      }
    }

    return map;
  }

  Map<String, int> _buildDefaultColumnMap(CardType type) {
    switch (type) {
      case CardType.basic:
        return {
          'front': 0,
          'back': 1,
          'frontHint': 2,
          'backHint': 3,
          'labels': 4,
        };
      case CardType.wordImage:
        return {
          'imageUrl': 0,
          'word': 1,
          'frontHint': 2,
          'backHint': 3,
          'labels': 4,
        };
      case CardType.threeFaces:
        return {
          'face1': 0,
          'face2': 1,
          'face3': 2,
          'frontHint': 3,
          'labels': 4,
        };
    }
  }

  bool _isValidRow(
      List<dynamic> row, CardType type, Map<String, int> columnMap,) {
    switch (type) {
      case CardType.basic:
        final frontIdx = columnMap['front'] ?? 0;
        final backIdx = columnMap['back'] ?? 1;
        return row.length > frontIdx &&
            row.length > backIdx &&
            row[frontIdx].toString().trim().isNotEmpty &&
            row[backIdx].toString().trim().isNotEmpty;

      case CardType.wordImage:
        final imageIdx = columnMap['imageUrl'] ?? 0;
        final wordIdx = columnMap['word'] ?? 1;
        return row.length > imageIdx &&
            row.length > wordIdx &&
            row[imageIdx].toString().trim().isNotEmpty &&
            row[wordIdx].toString().trim().isNotEmpty;

      case CardType.threeFaces:
        final face1Idx = columnMap['face1'] ?? 0;
        final face2Idx = columnMap['face2'] ?? 1;
        final face3Idx = columnMap['face3'] ?? 2;
        return row.length > face1Idx &&
            row.length > face2Idx &&
            row.length > face3Idx &&
            row[face1Idx].toString().trim().isNotEmpty &&
            row[face2Idx].toString().trim().isNotEmpty &&
            row[face3Idx].toString().trim().isNotEmpty;
    }
  }

  CardModel _createCardFromRow(
    List<dynamic> row,
    String deckId,
    CardType type,
    Map<String, int> columnMap,
    DateTime now,
  ) {
    String? frontHint;
    String? backHint;
    Map<String, dynamic> fields = {};
    String? imageUrl;
    List<String> labels = [];

    // Parse labels column (common for all card types)
    final labelsIdx = columnMap['labels'];
    if (labelsIdx != null && row.length > labelsIdx) {
      final labelsStr = row[labelsIdx].toString().trim();
      if (labelsStr.isNotEmpty) {
        // Split by space and filter empty strings
        labels =
            labelsStr.split(' ').where((l) => l.trim().isNotEmpty).toList();
      }
    }

    switch (type) {
      case CardType.basic:
        final frontIdx = columnMap['front'] ?? 0;
        final backIdx = columnMap['back'] ?? 1;
        final frontHintIdx = columnMap['frontHint'];
        final backHintIdx = columnMap['backHint'];

        fields = {
          'front': row[frontIdx].toString().trim(),
          'back': row[backIdx].toString().trim(),
        };

        if (frontHintIdx != null && row.length > frontHintIdx) {
          frontHint = row[frontHintIdx].toString().trim();
          if (frontHint.isEmpty) frontHint = null;
        }
        if (backHintIdx != null && row.length > backHintIdx) {
          backHint = row[backHintIdx].toString().trim();
          if (backHint.isEmpty) backHint = null;
        }
        break;

      case CardType.wordImage:
        final imageIdx = columnMap['imageUrl'] ?? 0;
        final wordIdx = columnMap['word'] ?? 1;
        final frontHintIdx = columnMap['frontHint'];
        final backHintIdx = columnMap['backHint'];

        imageUrl = row[imageIdx].toString().trim();
        fields = {
          'imageUrl': imageUrl,
          'word': row[wordIdx].toString().trim(),
        };

        if (frontHintIdx != null && row.length > frontHintIdx) {
          frontHint = row[frontHintIdx].toString().trim();
          if (frontHint.isEmpty) frontHint = null;
        }
        if (backHintIdx != null && row.length > backHintIdx) {
          backHint = row[backHintIdx].toString().trim();
          if (backHint.isEmpty) backHint = null;
        }
        break;

      case CardType.threeFaces:
        final face1Idx = columnMap['face1'] ?? 0;
        final face2Idx = columnMap['face2'] ?? 1;
        final face3Idx = columnMap['face3'] ?? 2;
        final frontHintIdx = columnMap['frontHint'];

        fields = {
          'face1': row[face1Idx].toString().trim(),
          'face2': row[face2Idx].toString().trim(),
          'face3': row[face3Idx].toString().trim(),
        };

        if (frontHintIdx != null && row.length > frontHintIdx) {
          frontHint = row[frontHintIdx].toString().trim();
          if (frontHint.isEmpty) frontHint = null;
        }
        break;
    }

    return CardModel(
      id: '',
      deckId: deckId,
      type: type,
      fields: fields,
      status: CardStatus.newCard,
      createdAt: now,
      updatedAt: now,
      nextReviewDate: now,
      imageUrl: imageUrl,
      frontHint: frontHint,
      backHint: backHint,
      tags: labels,
    );
  }

  String _getIconForCardType(CardType type) {
    switch (type) {
      case CardType.basic:
        return '✏️';
      case CardType.wordImage:
        return '🖼️';
      case CardType.threeFaces:
        return '🔺';
    }
  }
}

class _ImportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _ImportOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

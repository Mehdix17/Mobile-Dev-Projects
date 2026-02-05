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
                      'Import cards from a CSV file. Format: front,back (one card per row)',
                  onTap: _isLoading ? null : () => _importFromCsv(),
                ),
                const SizedBox(height: 12),
                _ImportOptionCard(
                  icon: Icons.text_snippet,
                  title: 'Import from Text',
                  description:
                      'Import cards from a text file with tab or comma separation',
                  onTap: _isLoading ? null : () => _importFromText(),
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
              'Your CSV file should have the following format:',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'front,back\n'
                'Hello,A greeting\n'
                'Goodbye,A farewell\n'
                '"How are you?","A common question"',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• First row can be a header (front,back) or data\n'
              '• Use quotes for text containing commas\n'
              '• Each row becomes one flashcard',
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

  Future<void> _importFromText() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv', 'tsv'],
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

    // Detect delimiter (comma, tab, or semicolon)
    final firstLine = contents.split('\n').first;
    String delimiter = ',';
    if (firstLine.contains('\t')) {
      delimiter = '\t';
    } else if (firstLine.contains(';') && !firstLine.contains(',')) {
      delimiter = ';';
    }

    final converter = CsvToListConverter(
      fieldDelimiter: delimiter,
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

    // Check if first row is a header
    int startIndex = 0;
    final firstRow = rows.first;
    if (firstRow.length >= 2) {
      final first = firstRow[0].toString().toLowerCase().trim();
      final second = firstRow[1].toString().toLowerCase().trim();
      if (first == 'front' && second == 'back' ||
          first == 'question' && second == 'answer' ||
          first == 'word' && second == 'definition') {
        startIndex = 1; // Skip header row
      }
    }

    // Filter valid rows
    final validRows = rows.sublist(startIndex).where((row) {
      return row.length >= 2 &&
          row[0].toString().trim().isNotEmpty &&
          row[1].toString().trim().isNotEmpty;
    }).toList();

    if (validRows.isEmpty) {
      setState(() {
        _isLoading = false;
        _statusMessage =
            'No valid cards found. Each row needs at least 2 columns.';
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
      icon: '📥',
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

    // Create cards
    final cards = validRows.map((row) {
      return CardModel(
        id: '',
        deckId: createdDeck.id,
        type: CardType.basic,
        fields: {
          'front': row[0].toString().trim(),
          'back': row[1].toString().trim(),
          if (row.length > 2) 'notes': row[2].toString().trim(),
        },
        status: CardStatus.newCard,
        createdAt: now,
        updatedAt: now,
        nextReviewDate: now,
      );
    }).toList();

    await cardRepo.batchCreateCards(cards);

    // Refresh decks
    ref.invalidate(decksProvider);
    ref.invalidate(recentDecksProvider);
    ref.invalidate(deckListProvider);

    setState(() {
      _isLoading = false;
      _statusMessage =
          'Successfully imported ${cards.length} cards to "$deckName"!';
    });

    if (mounted) {
      context.showSuccessSnackBar('Imported ${cards.length} cards!');
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

import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/decks/data/models/deck_model.dart';
import '../../features/cards/data/models/card_model.dart';

/// Service for loading predefined decks from CSV files
class PredefinedDecksLoader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  PredefinedDecksLoader({required this.userId});

  CollectionReference<Map<String, dynamic>> get _decksCollection {
    return _firestore.collection('users').doc(userId).collection('decks');
  }

  CollectionReference<Map<String, dynamic>> _cardsCollection(String deckId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId)
        .collection('cards');
  }

  /// Load all predefined decks from assets
  Future<List<Map<String, dynamic>>> loadPredefinedDecksData() async {
    final deckFiles = [
      {
        'file': 'assets/predefined_decks/01_english_basics.csv',
        'name': 'English Basics',
        'description': 'Common phrases, greetings, and polite expressions',
        'icon': '🗣️',
        'color': DeckColor.blue,
      },
      {
        'file': 'assets/predefined_decks/02_basic_math.csv',
        'name': 'Basic Math',
        'description': 'Arithmetic, geometry, and math fundamentals',
        'icon': '🔢',
        'color': DeckColor.green,
      },
      {
        'file': 'assets/predefined_decks/03_multilingual_basics.csv',
        'name': 'Multilingual Basics',
        'description': 'English/French/Spanish basics',
        'icon': '🌍',
        'color': DeckColor.purple,
      },
      {
        'file': 'assets/predefined_decks/04_world_geography.csv',
        'name': 'World Geography',
        'description': 'Countries, capitals, and landmarks',
        'icon': '🗺️',
        'color': DeckColor.orange,
      },
      {
        'file': 'assets/predefined_decks/05_programming_fundamentals.csv',
        'name': 'Programming Fundamentals',
        'description': 'Basic programming concepts',
        'icon': '💻',
        'color': DeckColor.indigo,
      },
      {
        'file': 'assets/predefined_decks/06_science_vocabulary.csv',
        'name': 'Science Vocabulary',
        'description': 'Biology, chemistry, and physics terms',
        'icon': '🔬',
        'color': DeckColor.teal,
      },
    ];

    final List<Map<String, dynamic>> decksData = [];

    for (var deckInfo in deckFiles) {
      try {
        final csvString =
            await rootBundle.loadString(deckInfo['file'] as String);
        final cards = await _parseCsvToCards(csvString, deckInfo);

        decksData.add({
          'info': deckInfo,
          'cards': cards,
        });
      } catch (e) {
        developer.log('Error loading deck ${deckInfo['name']}: $e');
      }
    }

    return decksData;
  }

  Future<List<Map<String, dynamic>>> _parseCsvToCards(
    String csvString,
    Map<String, dynamic> deckInfo,
  ) async {
    const converter = CsvToListConverter(
      fieldDelimiter: ',',
      eol: '\n',
      shouldParseNumbers: false,
    );

    final List<List<dynamic>> rows = converter.convert(csvString);

    if (rows.isEmpty) return [];

    // Get headers
    final headers =
        rows.first.map((col) => col.toString().toLowerCase().trim()).toList();
    const startIndex = 1; // Skip header row

    final List<Map<String, dynamic>> cards = [];

    for (var i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 2) continue;

      final cardType = _detectCardType(headers);
      final columnMap = _buildColumnMap(headers, cardType);

      final cardData = _createCardData(row, cardType, columnMap);
      if (cardData != null) {
        cards.add(cardData);
      }
    }

    return cards;
  }

  CardType _detectCardType(List<String> headers) {
    if (headers.any(
      (h) => h.contains('face1') || h.contains('face2') || h.contains('face3'),
    )) {
      return CardType.threeFaces;
    } else if (headers.any((h) => h.contains('imageurl') || h == 'image')) {
      return CardType.wordImage;
    } else {
      return CardType.basic;
    }
  }

  Map<String, int> _buildColumnMap(List<String> headers, CardType type) {
    final Map<String, int> map = {};

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];

      // Labels column (common for all types)
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

  Map<String, dynamic>? _createCardData(
    List<dynamic> row,
    CardType type,
    Map<String, int> columnMap,
  ) {
    String? frontHint;
    String? backHint;
    Map<String, dynamic> fields = {};
    String? imageUrl;
    List<String> labels = [];

    // Parse labels
    final labelsIdx = columnMap['labels'];
    if (labelsIdx != null && row.length > labelsIdx) {
      final labelsStr = row[labelsIdx].toString().trim();
      if (labelsStr.isNotEmpty) {
        labels =
            labelsStr.split(' ').where((l) => l.trim().isNotEmpty).toList();
      }
    }

    switch (type) {
      case CardType.basic:
        final frontIdx = columnMap['front'] ?? 0;
        final backIdx = columnMap['back'] ?? 1;

        if (row.length <= frontIdx || row.length <= backIdx) return null;

        final front = row[frontIdx].toString().trim();
        final back = row[backIdx].toString().trim();

        if (front.isEmpty || back.isEmpty) return null;

        fields = {'front': front, 'back': back};

        final frontHintIdx = columnMap['frontHint'];
        final backHintIdx = columnMap['backHint'];

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

        if (row.length <= imageIdx || row.length <= wordIdx) return null;

        imageUrl = row[imageIdx].toString().trim();
        final word = row[wordIdx].toString().trim();

        if (imageUrl.isEmpty || word.isEmpty) return null;

        fields = {'imageUrl': imageUrl, 'word': word};

        final frontHintIdx = columnMap['frontHint'];
        final backHintIdx = columnMap['backHint'];

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

        if (row.length <= face1Idx ||
            row.length <= face2Idx ||
            row.length <= face3Idx) {
          return null;
        }

        final face1 = row[face1Idx].toString().trim();
        final face2 = row[face2Idx].toString().trim();
        final face3 = row[face3Idx].toString().trim();

        if (face1.isEmpty || face2.isEmpty || face3.isEmpty) return null;

        fields = {'face1': face1, 'face2': face2, 'face3': face3};

        final frontHintIdx = columnMap['frontHint'];
        if (frontHintIdx != null && row.length > frontHintIdx) {
          frontHint = row[frontHintIdx].toString().trim();
          if (frontHint.isEmpty) frontHint = null;
        }
        break;
    }

    return {
      'type': type,
      'fields': fields,
      'imageUrl': imageUrl,
      'frontHint': frontHint,
      'backHint': backHint,
      'tags': labels,
    };
  }

  /// Import a specific predefined deck into user's collection
  Future<String?> importPredefinedDeck(String deckName) async {
    final decksData = await loadPredefinedDecksData();

    final deckData = decksData.firstWhere(
      (d) => d['info']['name'] == deckName,
      orElse: () => {},
    );

    if (deckData.isEmpty) return null;

    final deckInfo = deckData['info'] as Map<String, dynamic>;
    final cards = deckData['cards'] as List<Map<String, dynamic>>;

    // Create deck
    final deckRef = _decksCollection.doc();
    final now = DateTime.now();

    final deck = DeckModel(
      id: deckRef.id,
      name: deckInfo['name'] as String,
      description: deckInfo['description'] as String,
      color: deckInfo['color'] as DeckColor,
      icon: deckInfo['icon'] as String,
      createdAt: now,
      updatedAt: now,
      cardCount: cards.length,
      newCardCount: cards.length,
      dueCardCount: cards.length,
      tags: ['predefined'],
    );

    await deckRef.set(deck.toJson());

    // Create cards
    final batch = _firestore.batch();
    for (final cardData in cards) {
      final cardRef = _cardsCollection(deckRef.id).doc();
      final card = CardModel(
        id: cardRef.id,
        deckId: deckRef.id,
        type: cardData['type'] as CardType,
        fields: cardData['fields'] as Map<String, dynamic>,
        status: CardStatus.newCard,
        createdAt: now,
        updatedAt: now,
        nextReviewDate: now,
        imageUrl: cardData['imageUrl'] as String?,
        frontHint: cardData['frontHint'] as String?,
        backHint: cardData['backHint'] as String?,
        tags: List<String>.from(cardData['tags'] ?? []),
      );
      batch.set(cardRef, card.toJson());
    }
    await batch.commit();

    return deckRef.id;
  }
}

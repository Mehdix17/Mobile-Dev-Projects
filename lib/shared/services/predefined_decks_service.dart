import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/decks/data/models/deck_model.dart';
import '../../features/cards/data/models/card_model.dart';

/// Service to create predefined decks for new users
class PredefinedDecksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  PredefinedDecksService({required this.userId});

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

  /// Check if user has any decks
  Future<bool> hasExistingDecks() async {
    final snapshot = await _decksCollection.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Create all predefined decks with their cards
  Future<void> createPredefinedDecks() async {
    // Check if decks already exist
    if (await hasExistingDecks()) {
      return;
    }

    // Create predefined decks
    await _createBasicVocabularyDeck();
    await _createCommonPhrasesDeck();
    await _createIrregularVerbsDeck();
  }

  Future<void> _createBasicVocabularyDeck() async {
    final deckRef = _decksCollection.doc();
    final now = DateTime.now();

    final deck = DeckModel(
      id: deckRef.id,
      name: 'Basic Vocabulary',
      description:
          'Essential English words for beginners. Start your learning journey here!',
      color: DeckColor.blue,
      icon: '📚',
      createdAt: now,
      updatedAt: now,
      cardCount: 10,
      newCardCount: 10,
      dueCardCount: 10,
    );

    await deckRef.set(deck.toJson());

    final cards = [
      _createVocabCard(
        deckRef.id,
        'Hello',
        'A greeting used when meeting someone',
        'Hello! How are you?',
      ),
      _createVocabCard(
        deckRef.id,
        'Goodbye',
        'A parting phrase when leaving',
        'Goodbye! See you tomorrow.',
      ),
      _createVocabCard(
        deckRef.id,
        'Please',
        'A polite word used when making a request',
        'Please pass the salt.',
      ),
      _createVocabCard(
        deckRef.id,
        'Thank you',
        'An expression of gratitude',
        'Thank you for your help!',
      ),
      _createVocabCard(
        deckRef.id,
        'Sorry',
        'An expression of apology or regret',
        'I\'m sorry for being late.',
      ),
      _createVocabCard(
        deckRef.id,
        'Yes',
        'An affirmative response',
        'Yes, I would like some coffee.',
      ),
      _createVocabCard(
        deckRef.id,
        'No',
        'A negative response',
        'No, thank you. I\'m not hungry.',
      ),
      _createVocabCard(
        deckRef.id,
        'Help',
        'Assistance or aid',
        'Can you help me with this?',
      ),
      _createVocabCard(
        deckRef.id,
        'Water',
        'A clear liquid essential for life',
        'I\'d like a glass of water, please.',
      ),
      _createVocabCard(
        deckRef.id,
        'Food',
        'Substances eaten for nutrition',
        'The food here is delicious!',
      ),
    ];

    final batch = _firestore.batch();
    for (final card in cards) {
      final cardRef = _cardsCollection(deckRef.id).doc();
      batch.set(cardRef, card.copyWith(id: cardRef.id).toJson());
    }
    await batch.commit();
  }

  Future<void> _createCommonPhrasesDeck() async {
    final deckRef = _decksCollection.doc();
    final now = DateTime.now();

    final deck = DeckModel(
      id: deckRef.id,
      name: 'Common Phrases',
      description: 'Everyday English phrases for conversations',
      color: DeckColor.green,
      icon: '💬',
      createdAt: now,
      updatedAt: now,
      cardCount: 10,
      newCardCount: 10,
      dueCardCount: 10,
    );

    await deckRef.set(deck.toJson());

    final cards = [
      _createBasicCard(
        deckRef.id,
        'How are you?',
        'A common greeting asking about someone\'s well-being',
      ),
      _createBasicCard(
        deckRef.id,
        'Nice to meet you',
        'A polite phrase used when meeting someone for the first time',
      ),
      _createBasicCard(
        deckRef.id,
        'What\'s your name?',
        'A question to ask someone their name',
      ),
      _createBasicCard(
        deckRef.id,
        'Where are you from?',
        'A question about someone\'s origin or hometown',
      ),
      _createBasicCard(
        deckRef.id,
        'I don\'t understand',
        'A phrase to express confusion or lack of comprehension',
      ),
      _createBasicCard(
        deckRef.id,
        'Can you repeat that?',
        'A polite request to say something again',
      ),
      _createBasicCard(
        deckRef.id,
        'How much is this?',
        'A question about the price of something',
      ),
      _createBasicCard(
        deckRef.id,
        'Where is the bathroom?',
        'A question to find the restroom',
      ),
      _createBasicCard(
        deckRef.id,
        'I need help',
        'A phrase to request assistance',
      ),
      _createBasicCard(
        deckRef.id,
        'Have a nice day!',
        'A friendly farewell wishing someone well',
      ),
    ];

    final batch = _firestore.batch();
    for (final card in cards) {
      final cardRef = _cardsCollection(deckRef.id).doc();
      batch.set(cardRef, card.copyWith(id: cardRef.id).toJson());
    }
    await batch.commit();
  }

  Future<void> _createIrregularVerbsDeck() async {
    final deckRef = _decksCollection.doc();
    final now = DateTime.now();

    final deck = DeckModel(
      id: deckRef.id,
      name: 'Irregular Verbs',
      description: 'Master the most common English irregular verbs',
      color: DeckColor.purple,
      icon: '📝',
      createdAt: now,
      updatedAt: now,
      cardCount: 15,
      newCardCount: 15,
      dueCardCount: 15,
    );

    await deckRef.set(deck.toJson());

    final cards = [
      _createBasicCard(
        deckRef.id,
        'go → went → gone',
        'Base form, past simple, past participle of "go"',
      ),
      _createBasicCard(
        deckRef.id,
        'be → was/were → been',
        'Base form, past simple, past participle of "be"',
      ),
      _createBasicCard(
        deckRef.id,
        'have → had → had',
        'Base form, past simple, past participle of "have"',
      ),
      _createBasicCard(
        deckRef.id,
        'do → did → done',
        'Base form, past simple, past participle of "do"',
      ),
      _createBasicCard(
        deckRef.id,
        'say → said → said',
        'Base form, past simple, past participle of "say"',
      ),
      _createBasicCard(
        deckRef.id,
        'get → got → gotten/got',
        'Base form, past simple, past participle of "get"',
      ),
      _createBasicCard(
        deckRef.id,
        'make → made → made',
        'Base form, past simple, past participle of "make"',
      ),
      _createBasicCard(
        deckRef.id,
        'know → knew → known',
        'Base form, past simple, past participle of "know"',
      ),
      _createBasicCard(
        deckRef.id,
        'think → thought → thought',
        'Base form, past simple, past participle of "think"',
      ),
      _createBasicCard(
        deckRef.id,
        'take → took → taken',
        'Base form, past simple, past participle of "take"',
      ),
      _createBasicCard(
        deckRef.id,
        'see → saw → seen',
        'Base form, past simple, past participle of "see"',
      ),
      _createBasicCard(
        deckRef.id,
        'come → came → come',
        'Base form, past simple, past participle of "come"',
      ),
      _createBasicCard(
        deckRef.id,
        'give → gave → given',
        'Base form, past simple, past participle of "give"',
      ),
      _createBasicCard(
        deckRef.id,
        'find → found → found',
        'Base form, past simple, past participle of "find"',
      ),
      _createBasicCard(
        deckRef.id,
        'write → wrote → written',
        'Base form, past simple, past participle of "write"',
      ),
    ];

    final batch = _firestore.batch();
    for (final card in cards) {
      final cardRef = _cardsCollection(deckRef.id).doc();
      batch.set(cardRef, card.copyWith(id: cardRef.id).toJson());
    }
    await batch.commit();
  }

  CardModel _createVocabCard(
    String deckId,
    String word,
    String definition,
    String example,
  ) {
    final now = DateTime.now();
    return CardModel(
      id: '',
      deckId: deckId,
      type: CardType.basic,
      fields: {
        'front': word,
        'back': '$definition\n\nExample: $example',
      },
      status: CardStatus.newCard,
      createdAt: now,
      updatedAt: now,
      nextReviewDate: now,
    );
  }

  CardModel _createBasicCard(String deckId, String front, String back) {
    final now = DateTime.now();
    return CardModel(
      id: '',
      deckId: deckId,
      type: CardType.basic,
      fields: {
        'front': front,
        'back': back,
      },
      status: CardStatus.newCard,
      createdAt: now,
      updatedAt: now,
      nextReviewDate: now,
    );
  }
}

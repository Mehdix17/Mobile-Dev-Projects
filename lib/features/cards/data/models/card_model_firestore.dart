import 'package:cloud_firestore/cloud_firestore.dart';

/// Card types with their display info
enum CardType {
  basic(
    'Simple',
    '✏️',
    'Simple front/back card',
    ['front', 'back'],
    ['frontHint', 'backHint'],
  ),
  wordImage(
    'Image',
    '🖼️',
    'Image with text answer',
    ['imageUrl', 'word'],
    ['frontHint', 'backHint'],
  ),
  threeFaces(
    'Triple',
    '🔺',
    'Card with 3 sides (e.g., English/French/Arabic)',
    ['face1', 'face2', 'face3'],
    ['frontHint'],
  );

  final String displayName;
  final String icon;
  final String description;
  final List<String> requiredFields;
  final List<String> optionalFields;

  const CardType(
    this.displayName,
    this.icon,
    this.description,
    this.requiredFields,
    this.optionalFields,
  );
}

/// Card learning status
enum CardStatus {
  newCard('New'),
  learning('Learning'),
  review('Review'),
  mastered('Mastered');

  final String displayName;
  const CardStatus(this.displayName);
}

class CardModel {
  final String id;
  final String deckId;
  final CardType type;
  final Map<String, dynamic> fields;
  final CardStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime nextReviewDate;
  final int reviewCount;
  final int correctCount;
  final double interval;
  final double easeFactor;
  final String? imageUrl;
  final String? frontHint;
  final String? backHint;
  final List<String> tags;
  final int position;

  // Spaced repetition fields
  final int repetitions;
  final int timesCorrect;
  final int timesIncorrect;
  final int totalReviews;
  final double averageResponseTime;
  final DateTime? lastReviewedAt;

  CardModel({
    required this.id,
    required this.deckId,
    this.type = CardType.basic,
    this.fields = const {},
    this.status = CardStatus.newCard,
    required this.createdAt,
    required this.updatedAt,
    DateTime? nextReviewDate,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.interval = 1.0,
    this.easeFactor = 2.5,
    this.imageUrl,
    this.frontHint,
    this.backHint,
    this.tags = const [],
    this.position = 0,
    this.repetitions = 0,
    this.timesCorrect = 0,
    this.timesIncorrect = 0,
    this.totalReviews = 0,
    this.averageResponseTime = 0.0,
    this.lastReviewedAt,
  }) : nextReviewDate = nextReviewDate ?? DateTime.now();

  /// Get the front of the card based on card type
  String get front {
    switch (type) {
      case CardType.basic:
        return fields['front']?.toString() ?? '';
      case CardType.wordImage:
        return fields['imageUrl']?.toString() ?? '';
      case CardType.threeFaces:
        return fields['face1']?.toString() ?? '';
    }
  }

  /// Get the back of the card based on card type
  String get back {
    switch (type) {
      case CardType.basic:
        return fields['back']?.toString() ?? '';
      case CardType.wordImage:
        return fields['word']?.toString() ?? '';
      case CardType.threeFaces:
        return fields['face2']?.toString() ?? '';
    }
  }

  /// Get the third face (for 3-face cards)
  String get face3 {
    return fields['face3']?.toString() ?? '';
  }

  /// Check if this is a 3-face card
  bool get isThreeFaces => type == CardType.threeFaces;

  /// Check if card is due for review
  bool get isDueForReview =>
      DateTime.now().isAfter(nextReviewDate) ||
      DateTime.now().isAtSameMomentAs(nextReviewDate);

  /// Get accuracy percentage
  double get accuracy => totalReviews > 0 ? timesCorrect / totalReviews : 0.0;

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deckId': deckId,
      'type': type.name,
      'fields': fields,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'nextReviewDate': Timestamp.fromDate(nextReviewDate),
      'reviewCount': reviewCount,
      'correctCount': correctCount,
      'interval': interval,
      'easeFactor': easeFactor,
      'imageUrl': imageUrl,
      'frontHint': frontHint,
      'backHint': backHint,
      'tags': tags,
      'position': position,
      'repetitions': repetitions,
      'timesCorrect': timesCorrect,
      'timesIncorrect': timesIncorrect,
      'totalReviews': totalReviews,
      'averageResponseTime': averageResponseTime,
      'lastReviewedAt':
          lastReviewedAt != null ? Timestamp.fromDate(lastReviewedAt!) : null,
    };
  }

  /// Create from Firestore document
  factory CardModel.fromJson(Map<String, dynamic> json, String docId) {
    return CardModel(
      id: docId,
      deckId: json['deckId'] as String? ?? '',
      type: CardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CardType.basic,
      ),
      fields: Map<String, dynamic>.from(json['fields'] as Map? ?? {}),
      status: CardStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CardStatus.newCard,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextReviewDate:
          (json['nextReviewDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewCount: json['reviewCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      interval: (json['interval'] as num?)?.toDouble() ?? 1.0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      imageUrl: json['imageUrl'] as String?,
      frontHint: json['frontHint'] as String?,
      backHint: json['backHint'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      position: json['position'] as int? ?? 0,
      repetitions: json['repetitions'] as int? ?? 0,
      timesCorrect: json['timesCorrect'] as int? ?? 0,
      timesIncorrect: json['timesIncorrect'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      averageResponseTime:
          (json['averageResponseTime'] as num?)?.toDouble() ?? 0.0,
      lastReviewedAt: (json['lastReviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Create a new card
  factory CardModel.create({
    required String deckId,
    required CardType type,
    required Map<String, dynamic> fields,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return CardModel(
      id: '',
      deckId: deckId,
      type: type,
      fields: fields,
      tags: tags,
      createdAt: now,
      updatedAt: now,
      nextReviewDate: now,
    );
  }

  /// Create a copy with modified fields
  CardModel copyWith({
    String? id,
    String? deckId,
    CardType? type,
    Map<String, dynamic>? fields,
    CardStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? nextReviewDate,
    int? reviewCount,
    int? correctCount,
    double? interval,
    double? easeFactor,
    String? imageUrl,
    String? frontHint,
    String? backHint,
    List<String>? tags,
    int? position,
    int? repetitions,
    int? timesCorrect,
    int? timesIncorrect,
    int? totalReviews,
    double? averageResponseTime,
    DateTime? lastReviewedAt,
  }) {
    return CardModel(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      type: type ?? this.type,
      fields: fields ?? this.fields,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      imageUrl: imageUrl ?? this.imageUrl,
      frontHint: frontHint ?? this.frontHint,
      backHint: backHint ?? this.backHint,
      tags: tags ?? this.tags,
      position: position ?? this.position,
      repetitions: repetitions ?? this.repetitions,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesIncorrect: timesIncorrect ?? this.timesIncorrect,
      totalReviews: totalReviews ?? this.totalReviews,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  /// Get a field value by key
  dynamic getField(String key) => fields[key];
}

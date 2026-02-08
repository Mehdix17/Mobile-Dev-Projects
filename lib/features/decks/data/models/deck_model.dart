import 'package:cloud_firestore/cloud_firestore.dart';

enum DeckColor {
  blue(0xFF2196F3),
  green(0xFF4CAF50),
  orange(0xFFFF9800),
  purple(0xFF9C27B0),
  red(0xFFF44336),
  pink(0xFFE91E63),
  teal(0xFF009688),
  amber(0xFFFFC107),
  indigo(0xFF3F51B5),
  cyan(0xFF00BCD4),
  lime(0xFFCDDC39),
  deepOrange(0xFFFF5722);

  final int colorValue;
  const DeckColor(this.colorValue);
}

class DeckModel {
  final String id;
  final String name;
  final String description;
  final String? parentId;
  final List<String> tags;
  final DeckColor color;
  final String icon;
  final String? frontEmoji;
  final String? backEmoji;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int cardCount;
  final int newCardCount;
  final int dueCardCount;
  final DateTime? lastStudiedAt;
  final int dailyNewCardLimit;
  final int dailyReviewLimit;
  final bool shuffleCards;
  final bool isStarred;
  final bool isPublished;

  DeckModel({
    required this.id,
    required this.name,
    this.description = '',
    this.parentId,
    this.tags = const [],
    this.color = DeckColor.blue,
    this.icon = '📚',
    this.frontEmoji,
    this.backEmoji,
    required this.createdAt,
    required this.updatedAt,
    this.cardCount = 0,
    this.newCardCount = 0,
    this.dueCardCount = 0,
    this.lastStudiedAt,
    this.dailyNewCardLimit = 20,
    this.dailyReviewLimit = 100,
    this.shuffleCards = true,
    this.isStarred = false,
    this.isPublished = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentId': parentId,
      'tags': tags,
      'color': color.name,
      'icon': icon,
      'frontEmoji': frontEmoji,
      'backEmoji': backEmoji,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cardCount': cardCount,
      'newCardCount': newCardCount,
      'dueCardCount': dueCardCount,
      'lastStudiedAt':
          lastStudiedAt != null ? Timestamp.fromDate(lastStudiedAt!) : null,
      'dailyNewCardLimit': dailyNewCardLimit,
      'dailyReviewLimit': dailyReviewLimit,
      'shuffleCards': shuffleCards,
      'isStarred': isStarred,
      'isPublished': isPublished,
    };
  }

  factory DeckModel.fromJson(Map<String, dynamic> json, String docId) {
    return DeckModel(
      id: docId,
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      parentId: json['parentId'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      color: DeckColor.values.firstWhere(
        (e) => e.name == json['color'],
        orElse: () => DeckColor.blue,
      ),
      icon: json['icon'] as String? ?? '📚',
      frontEmoji: json['frontEmoji'] as String?,
      backEmoji: json['backEmoji'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cardCount: json['cardCount'] as int? ?? 0,
      newCardCount: json['newCardCount'] as int? ?? 0,
      dueCardCount: json['dueCardCount'] as int? ?? 0,
      lastStudiedAt: (json['lastStudiedAt'] as Timestamp?)?.toDate(),
      dailyNewCardLimit: json['dailyNewCardLimit'] as int? ?? 20,
      dailyReviewLimit: json['dailyReviewLimit'] as int? ?? 100,
      shuffleCards: json['shuffleCards'] as bool? ?? true,
      isStarred: json['isStarred'] as bool? ?? false,
      isPublished: json['isPublished'] as bool? ?? false,
    );
  }

  factory DeckModel.create({
    required String name,
    String description = '',
    String? parentId,
    List<String> tags = const [],
    DeckColor color = DeckColor.blue,
    String icon = '📚',
    String? frontEmoji,
    String? backEmoji,
  }) {
    final now = DateTime.now();
    return DeckModel(
      id: '',
      name: name,
      description: description,
      parentId: parentId,
      tags: tags,
      color: color,
      icon: icon,
      frontEmoji: frontEmoji,
      backEmoji: backEmoji,
      createdAt: now,
      updatedAt: now,
    );
  }

  DeckModel copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    List<String>? tags,
    DeckColor? color,
    String? icon,
    String? frontEmoji,
    String? backEmoji,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cardCount,
    int? newCardCount,
    int? dueCardCount,
    DateTime? lastStudiedAt,
    int? dailyNewCardLimit,
    int? dailyReviewLimit,
    bool? shuffleCards,
    bool? isStarred,
    bool? isPublished,
  }) {
    return DeckModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      frontEmoji: frontEmoji ?? this.frontEmoji,
      backEmoji: backEmoji ?? this.backEmoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardCount: cardCount ?? this.cardCount,
      newCardCount: newCardCount ?? this.newCardCount,
      dueCardCount: dueCardCount ?? this.dueCardCount,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      dailyNewCardLimit: dailyNewCardLimit ?? this.dailyNewCardLimit,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      shuffleCards: shuffleCards ?? this.shuffleCards,
      isStarred: isStarred ?? this.isStarred,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

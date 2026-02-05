import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus {
  inProgress,
  completed,
  paused;
}

enum StudyMode {
  flipCard(
    'Flip Card',
    '❓',
    'Flip cards to reveal answers',
    1,
  ),
  multipleChoice(
    'Multiple Choice',
    '🎯',
    'Select the correct answer from options',
    4,
  ),
  matchPairs('Match Pairs', '🧩', 'Match cards with their answers', 4);

  final String displayName;
  final String icon;
  final String description;
  final int minCards;

  const StudyMode(this.displayName, this.icon, this.description, this.minCards);
}

class StudySessionModel {
  final String id;
  final String deckId;
  final SessionStatus status;
  final StudyMode? mode;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalCards;
  final int correctCards;
  final int incorrectCards;
  final int totalTimeSeconds;
  final List<String> reviewedCardIds;
  final List<String>? filterTags;
  final List<String>? filterCardTypes;

  StudySessionModel({
    required this.id,
    required this.deckId,
    this.status = SessionStatus.inProgress,
    this.mode,
    required this.startTime,
    this.endTime,
    this.totalCards = 0,
    this.correctCards = 0,
    this.incorrectCards = 0,
    this.totalTimeSeconds = 0,
    this.reviewedCardIds = const [],
    this.filterTags,
    this.filterCardTypes,
  });

  // Computed properties for compatibility
  int get cardsStudied => totalCards;
  int get cardsCorrect => correctCards;
  Duration get duration => Duration(seconds: totalTimeSeconds);

  double get accuracy => totalCards > 0 ? (correctCards / totalCards) * 100 : 0;
  bool get isCompleted => status == SessionStatus.completed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deckId': deckId,
      'status': status.name,
      'mode': mode?.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'totalCards': totalCards,
      'correctCards': correctCards,
      'incorrectCards': incorrectCards,
      'totalTimeSeconds': totalTimeSeconds,
      'reviewedCardIds': reviewedCardIds,
      'filterTags': filterTags,
      'filterCardTypes': filterCardTypes,
    };
  }

  factory StudySessionModel.fromJson(Map<String, dynamic> json, String docId) {
    return StudySessionModel(
      id: docId,
      deckId: json['deckId'] as String? ?? '',
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.inProgress,
      ),
      mode: json['mode'] != null
          ? StudyMode.values.firstWhere(
              (e) => e.name == json['mode'],
              orElse: () => StudyMode.flipCard,
            )
          : null,
      startTime: (json['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (json['endTime'] as Timestamp?)?.toDate(),
      totalCards: json['totalCards'] as int? ?? 0,
      correctCards: json['correctCards'] as int? ?? 0,
      incorrectCards: json['incorrectCards'] as int? ?? 0,
      totalTimeSeconds: json['totalTimeSeconds'] as int? ?? 0,
      reviewedCardIds:
          List<String>.from(json['reviewedCardIds'] as List? ?? []),
      filterTags: json['filterTags'] != null
          ? List<String>.from(json['filterTags'] as List)
          : null,
      filterCardTypes: json['filterCardTypes'] != null
          ? List<String>.from(json['filterCardTypes'] as List)
          : null,
    );
  }

  factory StudySessionModel.create({required String deckId, StudyMode? mode}) {
    return StudySessionModel(
      id: '',
      deckId: deckId,
      mode: mode,
      startTime: DateTime.now(),
    );
  }

  void addReview({
    required String cardId,
    required String rating,
    required double responseTime,
    required bool correct,
  }) {
    // This is now handled via copyWith for immutability
    // but keeping for backward compatibility
  }

  void complete() {
    // This is now handled via copyWith for immutability
    // but keeping for backward compatibility
  }

  StudySessionModel copyWith({
    String? id,
    String? deckId,
    SessionStatus? status,
    StudyMode? mode,
    DateTime? startTime,
    DateTime? endTime,
    int? totalCards,
    int? correctCards,
    int? incorrectCards,
    int? totalTimeSeconds,
    List<String>? reviewedCardIds,
    List<String>? filterTags,
    List<String>? filterCardTypes,
  }) {
    return StudySessionModel(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalCards: totalCards ?? this.totalCards,
      correctCards: correctCards ?? this.correctCards,
      incorrectCards: incorrectCards ?? this.incorrectCards,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      reviewedCardIds: reviewedCardIds ?? this.reviewedCardIds,
      filterTags: filterTags ?? this.filterTags,
      filterCardTypes: filterCardTypes ?? this.filterCardTypes,
    );
  }
}

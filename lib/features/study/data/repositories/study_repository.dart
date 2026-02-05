import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_session_model.dart';

class StudyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  StudyRepository({required this.userId});

  CollectionReference<Map<String, dynamic>> get _sessionsCollection {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('studySessions');
  }

  Future<String> createSession(StudySessionModel session) async {
    final docRef = _sessionsCollection.doc();
    final newSession = session.copyWith(id: docRef.id);
    await docRef.set(newSession.toJson());
    return docRef.id;
  }

  Future<StudySessionModel?> getSession(String id) async {
    final doc = await _sessionsCollection.doc(id).get();
    if (!doc.exists) return null;
    return StudySessionModel.fromJson(doc.data()!, doc.id);
  }

  Future<List<StudySessionModel>> getSessionsByDeckId(String deckId) async {
    final snapshot = await _sessionsCollection
        .where('deckId', isEqualTo: deckId)
        .orderBy('startTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => StudySessionModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<StudySessionModel>> getRecentSessions({int limit = 10}) async {
    final snapshot = await _sessionsCollection
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => StudySessionModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<StudySessionModel>> getSessionsInDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _sessionsCollection
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('startTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => StudySessionModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateSession(StudySessionModel session) async {
    await _sessionsCollection.doc(session.id).update(session.toJson());
  }

  Future<void> completeSession(
    String id, {
    required int totalCards,
    required int correctCards,
    required int incorrectCards,
    required int totalTimeSeconds,
  }) async {
    await _sessionsCollection.doc(id).update({
      'status': SessionStatus.completed.name,
      'endTime': Timestamp.fromDate(DateTime.now()),
      'totalCards': totalCards,
      'correctCards': correctCards,
      'incorrectCards': incorrectCards,
      'totalTimeSeconds': totalTimeSeconds,
    });
  }

  Future<void> deleteSession(String id) async {
    await _sessionsCollection.doc(id).delete();
  }

  Future<int> getSessionCount() async {
    final snapshot = await _sessionsCollection.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getTodaySessionCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _sessionsCollection
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Stream<List<StudySessionModel>> watchSessions() {
    return _sessionsCollection
        .orderBy('startTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudySessionModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }
}

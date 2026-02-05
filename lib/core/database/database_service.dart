import 'firestore_service.dart';

/// Database service - now using Firebase Firestore
/// This is a compatibility layer to maintain existing code
class DatabaseService {
  /// Initialize Firebase
  static Future<void> initialize() async {
    await FirestoreService.initialize();
  }

  /// Close connections
  static Future<void> close() async {
    // Firestore handles connections automatically
  }

  /// Clear all data
  static Future<void> clearAll() async {
    await FirestoreService.clearAllUserData();
  }
}

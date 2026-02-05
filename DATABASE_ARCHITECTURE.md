# Database Architecture Documentation

## Overview

This English Flashcard application uses **Firebase Firestore** as its primary database. Firestore is a NoSQL, cloud-hosted, real-time database that provides automatic synchronization across devices and offline support.

## Why Firebase Firestore?

### Advantages
- ✅ **Cloud-Hosted**: Data is stored in Google's cloud infrastructure
- ✅ **Real-time Sync**: Automatic synchronization across devices
- ✅ **Offline Support**: Built-in offline persistence
- ✅ **Scalability**: Automatically scales with your user base
- ✅ **Security**: Firebase Authentication integration
- ✅ **No Server Required**: Backend-as-a-Service (BaaS)
- ✅ **Cross-Platform**: Works on Android, iOS, Web, Windows

### Key Features Used
- **Authentication**: Firebase Auth for user management
- **Collections & Documents**: Hierarchical NoSQL structure
- **Real-time Listeners**: Live data updates with `Stream` API
- **Batch Operations**: Atomic multi-document operations
- **Offline Persistence**: Automatic caching for offline use

---

## Database Structure

### Firestore Hierarchy

```
firestore (root)
│
└── users/ (collection)
    └── {userId}/ (document)
        ├── decks/ (subcollection)
        │   └── {deckId}/ (document)
        │       ├── name: string
        │       ├── description: string
        │       ├── color: string
        │       ├── icon: string
        │       ├── cardCount: number
        │       ├── tags: array
        │       ├── createdAt: timestamp
        │       ├── updatedAt: timestamp
        │       └── cards/ (subcollection)
        │           └── {cardId}/ (document)
        │               ├── type: "basic" | "wordImage" | "threeFaces"
        │               ├── fields: map
        │               ├── status: "newCard" | "learning" | "review" | "mastered"
        │               ├── nextReviewDate: timestamp
        │               ├── interval: number
        │               ├── easeFactor: number
        │               ├── repetitions: number
        │               ├── timesCorrect: number
        │               ├── timesIncorrect: number
        │               └── tags: array
        │
        ├── studySessions/ (subcollection)
        │   └── {sessionId}/ (document)
        │       ├── deckId: string
        │       ├── mode: "flipCard" | "multipleChoice" | "matchPairs"
        │       ├── startTime: timestamp
        │       ├── endTime: timestamp
        │       ├── totalCards: number
        │       ├── correctCards: number
        │       ├── incorrectCards: number
        │       ├── totalTimeSeconds: number
        │       └── status: "active" | "completed" | "abandoned"
        │
        └── data/ (subcollection)
            └── statistics/ (document)
                ├── totalStudySessions: number
                ├── totalStudyMinutes: number
                ├── totalCards: number
                ├── cardsNew: number
                ├── cardsLearning: number
                ├── cardsMastered: number
                ├── cardsReview: number
                ├── currentStreak: number
                ├── longestStreak: number
                ├── averageAccuracy: number
                └── lastStudyDate: timestamp
```

---

## Data Models

### 1. Deck Model

**Location**: `lib/features/decks/data/models/deck_model.dart`

```dart
{
  "id": "auto-generated-id",
  "name": "Basic English Vocabulary",
  "description": "Common words for beginners",
  "parentId": null,
  "tags": ["english", "beginner"],
  "color": "blue",
  "icon": "📚",
  "frontEmoji": "🇬🇧",
  "backEmoji": "🇫🇷",
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "cardCount": 50,
  "newCardCount": 20,
  "dueCardCount": 5,
  "lastStudiedAt": Timestamp,
  "dailyNewCardLimit": 20,
  "dailyReviewLimit": 100,
  "shuffleCards": true
}
```

**Key Fields**:
- `parentId`: Enables deck hierarchies (folders)
- `color`: One of 12 predefined colors (blue, green, orange, etc.)
- `dailyNewCardLimit`: SM-2 algorithm constraint
- `cardCount`: Denormalized for performance

### 2. Card Model

**Location**: `lib/features/cards/data/models/card_model_firestore.dart`

#### Card Types

1. **Basic Card**
```dart
{
  "id": "card-id",
  "deckId": "deck-id",
  "type": "basic",
  "fields": {
    "front": "Hello",
    "back": "Bonjour"
  },
  "frontHint": "A common greeting",
  "backHint": null,
  "status": "newCard",
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "nextReviewDate": Timestamp,
  "interval": 1.0,
  "easeFactor": 2.5,
  "repetitions": 0,
  "timesCorrect": 0,
  "timesIncorrect": 0,
  "tags": ["greetings"]
}
```

2. **Word-Image Card**
```dart
{
  "type": "wordImage",
  "fields": {
    "imageUrl": "/path/to/image.jpg",
    "word": "Apple"
  },
  "imageUrl": "/storage/emulated/0/...",
  // ... same other fields
}
```

3. **Three-Face Card**
```dart
{
  "type": "threeFaces",
  "fields": {
    "face1": "Hello",
    "face2": "Bonjour",
    "face3": "مرحبا"
  },
  // ... same other fields
}
```

#### Spaced Repetition Fields

The app implements the **SM-2 Algorithm** (SuperMemo 2):

- `interval`: Days until next review (1.0 → 6.0 → 15.0...)
- `easeFactor`: Difficulty multiplier (1.3 to 2.5)
- `repetitions`: Consecutive correct answers
- `nextReviewDate`: Calculated date for next review
- `status`: 
  - `newCard`: Never studied
  - `learning`: Currently being learned
  - `review`: Under spaced repetition
  - `mastered`: Long intervals, well-known

### 3. Study Session Model

**Location**: `lib/features/study/data/models/study_session_model.dart`

```dart
{
  "id": "session-id",
  "deckId": "deck-id",
  "mode": "flipCard",
  "startTime": Timestamp,
  "endTime": Timestamp,
  "totalCards": 20,
  "correctCards": 15,
  "incorrectCards": 5,
  "totalTimeSeconds": 180,
  "status": "completed",
  "cardResults": [
    {
      "cardId": "card-1",
      "rating": "good",
      "timeSpent": 5
    }
  ]
}
```

**Study Modes**:
- `flipCard`: Traditional flashcard flip
- `multipleChoice`: 4-option quiz
- `matchPairs`: Memory matching game

### 4. Statistics Model

**Location**: `lib/features/statistics/data/models/statistics_model.dart`

```dart
{
  "id": "statistics",
  "totalStudySessions": 45,
  "totalStudyMinutes": 230,
  "totalCards": 150,
  "cardsNew": 30,
  "cardsLearning": 50,
  "cardsMastered": 40,
  "cardsReview": 30,
  "currentStreak": 7,
  "longestStreak": 14,
  "averageAccuracy": 0.85,
  "lastStudyDate": Timestamp,
  "cardsStudiedToday": 20,
  "studyMinutesToday": 15,
  "sessionsToday": 2,
  "lastUpdatedAt": Timestamp
}
```

**Calculated Fields**:
- `overallProgress`: (cardsMastered / totalCards)
- Streak tracking with daily study detection

---

## Repository Pattern

The app uses the **Repository Pattern** to abstract Firestore operations.

### Repositories

1. **DeckRepository** (`lib/features/decks/data/repositories/deck_repository.dart`)
   - `createDeck()`, `updateDeck()`, `deleteDeck()`
   - `getAllDecks()`, `searchDecks()`, `getRecentDecks()`
   - `watchAllDecks()` → Stream for real-time updates

2. **CardRepository** (`lib/features/cards/data/repositories/card_repository.dart`)
   - `createCard()`, `updateCard()`, `deleteCard()`
   - `getCardsByDeckId()`, `getDueCards()`, `getNewCards()`
   - `batchCreateCards()` → Batch operations
   - `watchCards()` → Stream for live updates

3. **StudyRepository** (`lib/features/study/data/repositories/study_repository.dart`)
   - `createSession()`, `completeSession()`
   - `getSessionsByDeckId()`, `getRecentSessions()`
   - `getSessionsInDateRange()` → For analytics

4. **StatisticsRepository** (`lib/features/statistics/data/repositories/statistics_repository.dart`)
   - `getStatistics()`, `updateStatistics()`
   - `incrementStudySession()` → Automated stats updates
   - `updateCardCounts()` → Sync card status counts

### Core Service

**FirestoreService** (`lib/core/database/firestore_service.dart`)

Central service providing:
- Collection references
- Authentication checks
- Offline persistence initialization
- Batch operations
- Data cleanup utilities

---

## Data Flow

### 1. User Authentication
```
Firebase Auth → userId → Firestore path prefix
```

All data is scoped under `users/{userId}/`, ensuring complete data isolation between users.

### 2. Creating a Deck

```
UI → Provider → Repository → Firestore

DeckEditorScreen
  → deckNotifierProvider.createDeck()
    → DeckRepository.createDeck()
      → Firestore.collection('users/{uid}/decks').doc().set()
```

### 3. Studying Cards (SM-2 Algorithm)

```
1. Load due cards: CardRepository.getDueCards()
2. User rates card: DifficultyRating (again/hard/good/easy)
3. Calculate new interval: SM2Algorithm.calculate()
4. Update card: CardRepository.updateCard()
5. Log session: StudyRepository.createSession()
6. Update stats: StatisticsRepository.incrementStudySession()
```

### 4. Real-time Updates

```dart
// Provider watching Firestore stream
final decksStreamProvider = StreamProvider<List<DeckModel>>((ref) {
  return DeckRepository(userId).watchAllDecks();
});

// UI automatically rebuilds when data changes
ref.watch(decksStreamProvider)
```

---

## Firebase Configuration

### Project Setup

**Firebase Project**: `english-bce1b`

**Configured Platforms**:
- ✅ Android: `1:893334979209:android:f29d2290e7d776f6b4fc58`
- ✅ Web: `1:893334979209:web:b5312d4e8c064935b4fc58`
- ✅ Windows: `1:893334979209:web:e3663d91bf6a6a25b4fc58`

**Configuration Files**:
- `android/app/google-services.json` → Android config
- `lib/firebase_options.dart` → Flutter config (all platforms)
- `firebase.json` → Firebase CLI config

### Dependencies

```yaml
dependencies:
  firebase_core: ^3.1.0      # Core Firebase SDK
  cloud_firestore: ^5.0.0    # Firestore database
  firebase_auth: ^5.1.0      # Authentication
```

### Initialization

```dart
// main.dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
await FirestoreService.initialize(); // Enable offline persistence
```

---

## Offline Support

### How It Works

Firestore automatically caches data locally:
1. **Writes**: Stored locally first, synced when online
2. **Reads**: Served from cache when offline
3. **Conflict Resolution**: Last-write-wins strategy

### Implementation

```dart
// Enabled in FirestoreService.initialize()
await _firestore.enableNetwork();

// Queries work offline automatically
final decks = await getDecksCollection().get(); // Uses cache if offline
```

### Cache Behavior

- **Size**: ~40 MB default cache size
- **Persistence**: Survives app restarts
- **Eviction**: LRU (Least Recently Used)

---

## Security & Access Control

### Firestore Rules (Recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
  }
}
```

### Current Authentication

- **Anonymous Auth**: Users start without sign-up
- **Future**: Email/password, Google Sign-In, Apple Sign-In
- **User ID**: Auto-generated on first app launch

---

## Data Migration & Backup

### Exporting Data

The app supports export to:
- **JSON**: Full data structure
- **CSV**: Deck/card data in spreadsheet format

**Export Location**: 
```dart
// Uses share_plus & path_provider
final directory = await getApplicationDocumentsDirectory();
final file = File('${directory.path}/export.json');
```

### Importing Data

Supports importing:
- JSON files (full structure)
- CSV files (decks and cards)

**Import Handler**: `lib/features/import_export/`

### Firebase Console Backup

You can backup/restore from Firebase Console:
1. Go to Firebase Console → Firestore Database
2. Export data: Cloud Storage bucket → JSON format
3. Import data: Upload JSON to restore

---

## Performance Optimizations

### 1. Denormalization

```dart
// Card counts stored in deck document
{
  "cardCount": 50,        // Avoid counting cards collection
  "newCardCount": 20,     // Precomputed
  "dueCardCount": 5
}
```

### 2. Composite Indexes

Firestore automatically creates indexes for:
- Single field queries
- Compound queries (requires manual index)

**Example**: Querying due cards by date + deck
```dart
.where('nextReviewDate', isLessThanOrEqualTo: now)
.where('deckId', isEqualTo: deckId)
// Requires composite index in Firebase Console
```

### 3. Batch Operations

```dart
// Create multiple cards atomically
Future<void> batchCreateCards(List<CardModel> cards) async {
  final batch = _firestore.batch();
  for (var card in cards) {
    final docRef = _cardsCollection(card.deckId).doc();
    batch.set(docRef, card.toJson());
  }
  await batch.commit(); // Single network call
}
```

### 4. Pagination

```dart
// Load decks in chunks
await getDecksCollection()
  .orderBy('updatedAt', descending: true)
  .limit(20)
  .get();
```

---

## Limitations & Quotas

### Firestore Free Tier (Spark Plan)

| Resource | Free Quota |
|----------|-----------|
| Stored data | 1 GB |
| Document reads | 50,000/day |
| Document writes | 20,000/day |
| Document deletes | 20,000/day |
| Network egress | 10 GB/month |

### Document Limits

- **Max document size**: 1 MB
- **Max field depth**: 20 levels
- **Max writes/second/document**: ~1 write/second
- **Max subcollections**: Unlimited

**Mitigation**:
- Deck images stored as local file paths (not in Firestore)
- Large content uses external storage (could use Firebase Storage)

---

## Scalability Considerations

### Current Architecture
- **Single Region**: Default (flexible based on Firebase project region)
- **User Isolation**: Each user has separate data tree
- **Read Heavy**: Most operations are reads (study sessions)

### Scaling Strategy

1. **Horizontal Scaling** (Automatic)
   - Firestore auto-scales with document count
   - No manual sharding needed

2. **Shared Decks** (Future: Marketplace)
   - Create separate `marketplace` collection
   - Reference decks by ID, not duplication
   - Use Cloud Functions for server-side logic

3. **Analytics** (Future)
   - Firebase Analytics for usage tracking
   - BigQuery export for advanced queries

---

## Alternative: Realtime Database vs Firestore

### Why Firestore Was Chosen

| Feature | Firestore | Realtime Database |
|---------|-----------|-------------------|
| Data Model | Documents & Collections | JSON tree |
| Queries | Rich querying | Limited queries |
| Scaling | Automatic | Manual sharding |
| Offline | Advanced | Basic |
| Pricing | Pay-per-operation | Pay-per-GB |

**Decision**: Firestore's document model fits flashcards naturally (decks → cards hierarchy), and complex queries (due cards, tags) are essential.

---

## Hosting Data on Firebase

### ✅ **Yes, It's Already Hosted!**

Your data **is already hosted on Firebase Cloud Firestore**. Here's what that means:

#### Current Setup
- **Cloud-hosted**: All user data is in Google's Firebase infrastructure
- **No local database**: No SQLite, no local files for data
- **Automatic sync**: Data syncs across all user devices
- **Global CDN**: Firebase uses Google's edge network

#### Data Location
- Firebase project: `english-bce1b`
- Region: Auto-selected during Firebase project creation
- Access: Firebase Console → Firestore Database

#### What's NOT on Firebase
- **Images**: Stored locally on device (`/storage/emulated/0/`)
- **Audio**: Generated dynamically (sound effects)
- **App code**: Distributed via app stores

### Adding Firebase Storage (Future Enhancement)

To store images in the cloud:

```dart
// Add firebase_storage to pubspec.yaml
dependencies:
  firebase_storage: ^12.0.0

// Upload image
final ref = FirebaseStorage.instance
  .ref('users/$userId/images/$imageId.jpg');
await ref.putFile(imageFile);
final imageUrl = await ref.getDownloadURL();

// Update card with cloud URL
card.imageUrl = imageUrl;
```

**Benefits**:
- Images sync across devices
- Automatic CDN delivery
- Optimized thumbnails (via Firebase Extensions)

**Free Tier**: 5 GB storage, 1 GB/day downloads

---

## Database Migration Path

### Current: Firebase Firestore ✅
### Future Options:

1. **Stay with Firestore** (Recommended)
   - Add Firebase Storage for images
   - Add Cloud Functions for backend logic
   - Export to BigQuery for analytics

2. **Hybrid Approach**
   - Firestore for user data
   - PostgreSQL (Supabase) for marketplace/analytics
   - Redis for caching

3. **Self-Hosted** (Advanced)
   - Migrate to PostgreSQL/MongoDB
   - Requires custom backend API
   - Loses real-time sync features

---

## Developer Commands

### View Data
```bash
# Firebase Console
https://console.firebase.google.com/project/english-bce1b/firestore

# Or use Firebase CLI
firebase firestore:indexes
firebase firestore:delete --all-collections
```

### Export Data
```bash
# Export to JSON
gcloud firestore export gs://english-bce1b.appspot.com/backups

# Import from JSON
gcloud firestore import gs://english-bce1b.appspot.com/backups/2024-01-01
```

### Test Firestore Rules
```bash
firebase emulators:start --only firestore
```

---

## Troubleshooting

### Common Issues

1. **"User not authenticated" error**
   ```dart
   // Ensure Firebase Auth is initialized
   await FirebaseAuth.instance.signInAnonymously();
   ```

2. **Offline mode not working**
   ```dart
   // Check if persistence is enabled
   await FirestoreService.initialize();
   ```

3. **Data not syncing**
   - Check internet connection
   - Verify Firestore rules allow access
   - Check Firebase Console for errors

4. **Quota exceeded**
   - Monitor usage in Firebase Console
   - Implement caching to reduce reads
   - Consider upgrading to Blaze plan

---

## Summary

### ✅ **Your app uses Firebase Firestore**
- Cloud-hosted NoSQL database
- Real-time sync across devices
- Offline support built-in
- Scales automatically
- Secure with Firebase Auth

### 📊 **Data is organized as**:
```
users/{userId}/
  ├── decks/{deckId}
  │   └── cards/{cardId}
  ├── studySessions/{sessionId}
  └── data/statistics
```

### 🚀 **Hosting Status**:
- ✅ Database: **Hosted on Firebase Cloud**
- ✅ Authentication: **Firebase Auth**
- ⚠️ Images: **Local storage** (can migrate to Firebase Storage)
- ✅ Offline: **Automatic caching**

### 📈 **Next Steps**:
1. Configure Firestore security rules
2. Add Firebase Storage for images
3. Set up Cloud Functions for marketplace
4. Monitor usage in Firebase Console
5. Plan for scaling (Blaze plan if needed)

---

**Last Updated**: February 5, 2026  
**Firebase Project**: english-bce1b  
**Database**: Cloud Firestore  
**Region**: Auto-configured

# Cardly

<div align="center">

<img src="assets/images/logo.png" alt="Cardly Logo" width="150"/>

### Smart Flashcards for Smart Learning

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A powerful Flutter flashcard application for learning any topic with spaced repetition**

[Features](#-key-features) • [Getting Started](#-getting-started) • [Documentation](#-project-structure) • [Contributing](#-contributing)

</div>

---

## 📖 Table of Contents

- [About](#about)
- [Key Features](#-key-features)
- [Screenshots](#-screenshots)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Architecture](#️-architecture)
- [Development](#️-development)
- [Contributing](#-contributing)
- [License](#-license)

## About

Cardly is a comprehensive flashcard application built with Flutter and Firebase that helps you learn and memorize any topic effectively. Using the proven SM-2 spaced repetition algorithm, Cardly ensures you review cards at optimal intervals for maximum retention.

Perfect for learning languages, vocabulary, concepts, exam preparation, and more!

## ✨ Key Features

### 📚 Card Management

- **3 Flexible Card Types**:
  - **Simple** ✏️ - Classic front/back flashcards
  - **Image** 🖼️ - Visual learning with image-to-text cards
  - **Triple** 🔺 - Three-sided cards (e.g., English/French/Arabic)
- **Smart Organization**: Color-coded decks with progress tracking
- **Tagging System**: Organize and filter cards with custom tags
- **Predefined Decks**: Starter decks for common topics

### 🧠 Study Modes

- **Flip Card** ❓ - Classic flashcard experience with smooth flip animations
- **Multiple Choice** 🎯 - Quiz format with auto-generated options
- **Match Pairs** 🧩 - Memory-style matching game

### 📊 Spaced Repetition (SM-2 Algorithm)

- **Intelligent Scheduling**: SuperMemo 2 algorithm for optimal review timing
- **Difficulty Ratings**: Again, Hard, Good, Easy
- **Adaptive Intervals**: From 1 day to extended periods based on performance
- **Card Status Tracking**: New, Learning, Review, Mastered
- **Automatic Review Scheduling**: Cards appear when you need to review them

### 📈 Statistics & Analytics

- **Study Progress**: Track daily study sessions and streaks
- **Performance Metrics**: Accuracy charts and time analytics
- **Card Distribution**: Monitor card status across all decks
- **Session History**: Review past study sessions and results

### ☁️ Cloud Features

- **Firebase Integration**: Real-time cloud synchronization
- **Multi-Device Support**: Access your decks from anywhere
- **Offline Mode**: Study without internet, sync when online
- **Authentication**: Anonymous sign-in or Google Sign-In

### 🌐 Marketplace & Sharing

- **Deck Sharing**: Share your decks with the community
- **Discover Decks**: Browse and import shared decks
- **Import/Export**:
  - JSON format for backup and transfer
  - CSV spreadsheet import/export
  - Anki deck import (.apkg files)

## 📱 Screenshots

> Screenshots coming soon! The app features a modern Material 3 design with light and dark themes.

## ⚡ Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/cardly.git
cd cardly

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase (first time only)
flutterfire configure

# 4. Run the app
flutter run
```

That's it! The app will automatically sign in anonymously and you can start creating decks and cards.

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.19+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: 3.3+
- **IDE**: Android Studio, VS Code, or IntelliJ IDEA
- **Firebase Account**: For backend services ([Firebase Console](https://console.firebase.google.com/))

### Firebase Setup

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use an existing one

2. **Enable Firebase Services**
   - **Authentication**: Enable Anonymous and Google Sign-In methods
   - **Firestore Database**: Create a database in production mode
   - Configure security rules for your app

3. **Add Firebase to Your App**
   - Download `google-services.json` for Android
   - Place it in `android/app/`
   - Run `flutterfire configure` to generate `firebase_options.dart`

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/cardly.git
   cd cardly
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (if not already done)

   ```bash
   # Install FlutterFire CLI if needed
   dart pub global activate flutterfire_cli

   # Configure Firebase for your project
   flutterfire configure
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Font Setup (Optional)

The app uses the **Inter** font family. To use custom fonts:

1. Download [Inter font](https://fonts.google.com/specimen/Inter)
2. Place font files in `assets/fonts/`:
   - Inter-Regular.ttf
   - Inter-Medium.ttf
   - Inter-SemiBold.ttf
   - Inter-Bold.ttf

> Note: The app will fall back to system fonts if custom fonts are not provided.

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/       # App, study, and theme constants
│   ├── database/        # Firebase service initialization
│   ├── router/          # GoRouter navigation configuration
│   ├── theme/           # Material 3 theming (light/dark modes)
│   └── utils/           # Helpers, extensions, and algorithms (SM-2)
├── features/
│   ├── auth/            # Authentication screens and logic
│   ├── cards/           # Card CRUD operations and models
│   ├── decks/           # Deck management and organization
│   ├── home/            # Home dashboard with quick stats
│   ├── import_export/   # Data import/export functionality
│   ├── marketplace/     # Community deck sharing
│   ├── settings/        # App settings and preferences
│   ├── statistics/      # Analytics and progress charts
│   └── study/           # Study modes and session tracking
└── shared/
    ├── services/        # Shared services (auth, notifications, etc.)
    └── widgets/         # Reusable UI components
```

## 🏗️ Architecture

This app follows **Clean Architecture** principles with a **Feature-First** organization:

### Layers

- **Presentation Layer**:
  - Screens (UI)
  - Widgets (reusable components)
  - Providers (Riverpod state management)
- **Domain Layer**:
  - Business logic
  - Use cases
  - Entities

- **Data Layer**:
  - Models (Firebase Firestore)
  - Repositories
  - Data sources

### Key Technologies

| Category             | Technology                    |
| -------------------- | ----------------------------- |
| **Framework**        | Flutter 3.19+                 |
| **Language**         | Dart 3.3+                     |
| **State Management** | Riverpod (flutter_riverpod)   |
| **Backend**          | Firebase (Firestore + Auth)   |
| **Navigation**       | GoRouter                      |
| **Charts**           | FL Chart, Heatmap Calendar    |
| **Animations**       | Flutter Animate               |
| **UI Components**    | Card Swiper, Slidable         |
| **Import/Export**    | CSV, Archive, QR Flutter      |
| **Authentication**   | Firebase Auth, Google Sign-In |
| **Notifications**    | Flutter Local Notifications   |
| **Audio**            | Audioplayers                  |

## 🎯 Core Algorithms

### SM-2 Spaced Repetition

The app uses the **SuperMemo 2** algorithm for optimal card scheduling:

- **Ease Factor**: Adjusts based on recall difficulty (2.5 default)
- **Intervals**: Dynamically calculated (1 day → weeks → months)
- **Quality Ratings**:
  - Again (0): Reset to learning
  - Hard (1-2): Reduce ease factor
  - Good (3): Standard progression
  - Easy (4-5): Accelerated progression

## 📱 Features in Detail

### Card Types

1. **Simple Cards** ✏️
   - Traditional front/back format
   - Perfect for basic vocabulary, definitions, Q&A
   - Optional hints for both sides

2. **Image Cards** 🖼️
   - Visual learning with images
   - Image on front, text answer on back
   - Great for object recognition, visual vocabulary

3. **Triple Cards** 🔺
   - Three sides/faces
   - Ideal for multilingual learning (e.g., English/French/Arabic)
   - Flexible for complex concepts

### Study Session Features

- **Smart Card Selection**: Prioritizes due cards
- **Progress Tracking**: Real-time accuracy and timing
- **Session Summary**: Detailed review after each session
- **Filter Options**: Study by tags or card types

### Statistics Dashboard

- **Heatmap Calendar**: Visual representation of study activity
- **Accuracy Charts**: Track improvement over time
- **Time Analytics**: Monitor study duration and efficiency
- **Card Distribution**: See how many cards are in each status

## 🔐 Security & Privacy

- **Firebase Authentication**: Secure user management
- **Firestore Security Rules**: Protect user data
- **Anonymous Mode**: Study without creating an account
- **Offline Support**: Local caching for privacy and performance

## 🛠️ Development

### Code Generation

This project uses code generation for Riverpod providers:

```bash
# Watch for changes and auto-generate
dart run build_runner watch --delete-conflicting-outputs

# One-time generation
dart run build_runner build --delete-conflicting-outputs
```

### Project Commands

```bash
# Run the app
flutter run

# Run in release mode
flutter run --release

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

### Environment Setup

The app automatically signs in anonymously if no user is authenticated. To enable full authentication:

1. Enable **Anonymous Auth** in Firebase Console
2. Enable **Google Sign-In** (optional)
3. Configure sign-in methods in Authentication settings

## 🧪 Testing

The app includes unit tests for core functionality:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Test Coverage

- Card type validations
- SM-2 algorithm calculations
- Study session logic
- Data model serialization

## 📦 Dependencies

### Main Dependencies

- `flutter_riverpod` - State management
- `firebase_core` - Firebase initialization
- `cloud_firestore` - Cloud database
- `firebase_auth` - Authentication
- `google_sign_in` - Google authentication
- `go_router` - Navigation
- `fl_chart` - Charts and graphs
- `flutter_animate` - Animations
- `card_swiper` - Swipe gestures
- `flutter_slidable` - Slide actions
- `csv` - CSV import/export
- `qr_flutter` - QR code generation
- `file_picker` - File selection
- `share_plus` - Sharing functionality
- `flutter_local_notifications` - Local notifications
- `audioplayers` - Audio playback
- `emoji_picker_flutter` - Emoji selection

See [pubspec.yaml](pubspec.yaml) for complete list.

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes**
   - Follow the existing code style
   - Add tests if applicable
   - Update documentation
4. **Commit your changes**
   ```bash
   git commit -m "Add amazing feature"
   ```
5. **Push to your branch**
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request**

### Development Guidelines

- Follow Flutter/Dart best practices
- Use meaningful variable and function names
- Comment complex logic
- Keep functions small and focused
- Write tests for new features
- Update README for significant changes

## 🐛 Known Issues & Roadmap

### Known Issues

- Some import/export features are in development
- Marketplace sharing is being enhanced

### Future Features

- [ ] Custom study algorithms
- [ ] AI-powered card generation
- [ ] Voice recording for cards
- [ ] Collaborative decks
- [ ] Advanced statistics
- [ ] Multi-language UI
- [ ] Web and desktop support
- [ ] Gamification elements

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **SuperMemo** - For the SM-2 algorithm
- **Flutter Team** - For the amazing framework
- **Firebase** - For backend services
- **Community** - For feedback and contributions

## 📞 Support

- 📧 Email: support@cardly.app
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/cardly/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/cardly/discussions)

---

**Made with ❤️ using Flutter**

_Cardly - Smart Flashcards for Smart Learning_

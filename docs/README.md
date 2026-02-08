# Cardly

<div align="center">

<img src="assets/images/logo.png" alt="Cardly Logo" width="150"/>

### Smart Flashcards for Smart Learning

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**A powerful Flutter flashcard application for learning any topic with spaced repetition**

[Website](https://yourusername.github.io/cardly) • [Mobile App](https://github.com/yourusername/cardly#mobile-app) • [Download](https://github.com/yourusername/cardly/releases)

</div>

---

## 📦 Repository Structure

This is a monorepo containing both the Cardly mobile app and its landing page website.

```
cardly/
├── lib/              # Flutter mobile app
├── android/          # Android platform code
├── ios/              # iOS platform code
├── assets/           # App assets
├── website/          # Landing page (HTML/CSS/JS)
├── pubspec.yaml      # Flutter dependencies
└── README.md         # This file
```

## 📱 Mobile App

A comprehensive flashcard application built with Flutter and Firebase featuring:

- **3 Card Types**: Simple, Image, and Triple cards
- **Smart Study Modes**: Flip cards, multiple choice, match pairs
- **SM-2 Algorithm**: Intelligent spaced repetition
- **Cloud Sync**: Multi-device support with Firebase
- **Offline Mode**: Study without internet
- **Analytics**: Track your learning progress

### Quick Start (Mobile)

```bash
# Clone repository
git clone https://github.com/yourusername/cardly.git
cd cardly

# Install dependencies
flutter pub get

# Configure Firebase
flutterfire configure

# Run app
flutter run
```

📖 **Full mobile app documentation**: See inline documentation in code

## 🌐 Website

Static landing page for the Cardly app. Built with vanilla HTML, CSS, and JavaScript.

### Quick Start (Website)

```bash
cd website

# Open in browser or use a local server
python -m http.server 8000
```

📖 **Full website documentation**: See [website/README.md](website/README.md)

### Deploy to GitHub Pages

1. Go to repository **Settings** → **Pages**
2. Source: Deploy from branch `main`
3. Folder: `/ (root)` or `/website`
4. Save

Your site will be live at: `https://yourusername.github.io/cardly`

## ✨ Key Features

### 📚 Card Management

- Multiple card types for different learning styles
- Color-coded decks with progress tracking
- Tagging system for organization
- Import/Export (JSON, CSV, Anki)

### 🧠 Smart Learning

- **SM-2 Algorithm**: Scientifically proven spaced repetition
- **Adaptive Intervals**: 1 day → weeks → months
- **Card States**: New → Learning → Review → Mastered
- **Smart Scheduling**: Study cards when you need to

### 📊 Analytics

- Study streaks and session history
- Accuracy charts and time tracking
- Heatmap calendar visualization
- Card distribution insights

### ☁️ Cloud & Sync

- Real-time Firebase synchronization
- Multi-device support
- Offline support with automatic sync
- Anonymous or Google Sign-In

## 🛠️ Tech Stack

### Mobile App

| Category         | Technology                  |
| ---------------- | --------------------------- |
| Framework        | Flutter 3.19+               |
| Language         | Dart 3.3+                   |
| State Management | Riverpod                    |
| Backend          | Firebase (Firestore + Auth) |
| Navigation       | GoRouter                    |
| UI               | Material 3 Design           |

### Website

| Category | Technology                      |
| -------- | ------------------------------- |
| Frontend | HTML5, CSS3, JavaScript (ES6+)  |
| Styling  | Custom CSS (CSS Variables)      |
| Hosting  | GitHub Pages / Netlify / Vercel |

## 🚀 Development

### Mobile App Development

```bash
# Install dependencies
flutter pub get

# Generate code (Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Build release APK
flutter build apk --release

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Website Development

```bash
cd website

# No build step needed - edit HTML/CSS/JS directly

# Test locally
python -m http.server 8000
# or
npx http-server
```

## 📖 Documentation

- **Mobile App**: Architecture follows Clean Architecture with Feature-First organization
- **Firebase Setup**: See [Firebase Console Setup Guide](#firebase-setup)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md) (coming soon)
- **API Docs**: Generated from code comments

## 🤝 Contributing

Contributions are welcome! Whether you want to:

- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🎨 Design improvements
- 💻 Code contributions

Please feel free to open an issue or submit a pull request.

### Development Guidelines

- Follow Flutter/Dart best practices
- Write meaningful commit messages
- Add tests for new features
- Update documentation
- Keep code clean and commented

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **SuperMemo** - For the SM-2 algorithm
- **Flutter Team** - For the amazing framework
- **Firebase** - For backend services
- **Community** - For feedback and contributions

## 📞 Support & Contact

- 🌐 **Website**: [cardly.app](https://yourusername.github.io/cardly)
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/cardly/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/cardly/discussions)
- 📧 **Email**: support@cardly.app

---

<div align="center">

**Made with ❤️ using Flutter**

_Cardly - Smart Flashcards for Smart Learning_

</div>

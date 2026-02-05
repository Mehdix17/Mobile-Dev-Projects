extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Remove all whitespace
  String get removeWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Normalize whitespace (collapse multiple spaces)
  String get normalizeWhitespace {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Convert to snake_case
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  /// Convert to camelCase
  String get toCamelCase {
    final words = split(RegExp(r'[\s_-]+'));
    if (words.isEmpty) return this;
    return words.first.toLowerCase() +
        words.skip(1).map((w) => w.capitalize).join();
  }

  /// Calculate Levenshtein distance (for fuzzy matching)
  int levenshteinDistance(String other) {
    if (this == other) return 0;
    if (isEmpty) return other.length;
    if (other.isEmpty) return length;

    final s1 = toLowerCase();
    final s2 = other.toLowerCase();

    List<int> v0 = List.generate(s2.length + 1, (i) => i);
    List<int> v1 = List.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(
          (a, b) => a < b ? a : b,
        );
      }

      final temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  /// Calculate similarity percentage (0-100)
  int similarityTo(String other) {
    if (toLowerCase() == other.toLowerCase()) return 100;
    if (isEmpty || other.isEmpty) return 0;

    final maxLength = length > other.length ? length : other.length;
    final distance = levenshteinDistance(other);

    return ((1 - distance / maxLength) * 100).round();
  }

  /// Check if strings match with fuzzy threshold
  bool fuzzyMatches(String other, {int threshold = 80}) {
    return similarityTo(other) >= threshold;
  }

  /// Extract words for sentence building
  List<String> get words {
    return split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  /// Scramble words in a sentence
  String get scrambleWords {
    final wordList = words;
    wordList.shuffle();
    return wordList.join(' ');
  }

  /// Create a fill-in-the-blank version
  /// Returns a tuple of (sentence with blanks, list of blanked words)
  (String, List<String>) createBlanks({int numberOfBlanks = 1}) {
    final wordList = words;
    if (wordList.length <= numberOfBlanks) {
      return ('_____', wordList);
    }

    final blankedWords = <String>[];
    final indices = List.generate(wordList.length, (i) => i)..shuffle();
    final indicesToBlank = indices.take(numberOfBlanks).toList()..sort();

    for (final index in indicesToBlank) {
      blankedWords.add(wordList[index]);
      wordList[index] = '_____';
    }

    return (wordList.join(' '), blankedWords);
  }

  /// Highlight a word in the sentence
  String highlightWord(
    String word, {
    String prefix = '**',
    String suffix = '**',
  }) {
    return replaceAll(
      RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false),
      '$prefix$word$suffix',
    );
  }
}

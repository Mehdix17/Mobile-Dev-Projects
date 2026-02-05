import 'package:flutter/material.dart';

class PredefinedTag {
  final String name;
  final Color color;

  const PredefinedTag(this.name, this.color);
}

class PredefinedTags {
  static const List<PredefinedTag> tags = [
    PredefinedTag('noun', Color(0xFF2196F3)), // Blue
    PredefinedTag('verb', Color(0xFF4CAF50)), // Green
    PredefinedTag('adjective', Color(0xFFFF9800)), // Orange
    PredefinedTag('adverb', Color(0xFF9C27B0)), // Purple
    PredefinedTag('phrase', Color(0xFF00BCD4)), // Cyan
    PredefinedTag('idiom', Color(0xFF009688)), // Teal
    PredefinedTag('expression', Color(0xFFE91E63)), // Pink
    PredefinedTag('slang', Color(0xFFFF5722)), // Deep Orange
  ];

  static Color? getColorForTag(String tag) {
    try {
      return tags.firstWhere((t) => t.name == tag).color;
    } catch (_) {
      return null;
    }
  }

  static List<String> get tagNames => tags.map((t) => t.name).toList();
}

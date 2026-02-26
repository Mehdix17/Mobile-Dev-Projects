import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

final settingsProvider = ChangeNotifierProvider<SettingsNotifier>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  int _dailyNewCardLimit = 20;
  int _dailyReviewLimit = 100;
  bool _notificationsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  int _newCardsPerDay = 20;
  int _reviewsPerDay = 100;
  String _cardDirectionMode = 'shuffle'; // 'shuffle', 'frontFirst', 'backFirst'

  ThemeMode get themeMode => _themeMode;
  int get dailyNewCardLimit => _dailyNewCardLimit;
  int get dailyReviewLimit => _dailyReviewLimit;
  bool get notificationsEnabled => _notificationsEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  int get newCardsPerDay => _newCardsPerDay;
  int get reviewsPerDay => _reviewsPerDay;
  String get cardDirectionMode => _cardDirectionMode;

  SettingsNotifier() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeIndex = prefs.getInt(AppConstants.themeModePrefKey) ?? 1;
    _themeMode = ThemeMode.values[themeModeIndex];

    _dailyNewCardLimit =
        prefs.getInt(AppConstants.dailyNewCardLimitPrefKey) ?? 20;
    _dailyReviewLimit =
        prefs.getInt(AppConstants.dailyReviewLimitPrefKey) ?? 100;
    _notificationsEnabled =
        prefs.getBool(AppConstants.notificationsEnabledPrefKey) ?? true;

    final reminderTimeString =
        prefs.getString(AppConstants.reminderTimePrefKey);
    if (reminderTimeString != null) {
      final parts = reminderTimeString.split(':');
      _reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    _cardDirectionMode = prefs.getString('cardDirectionMode') ?? 'shuffle';

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.themeModePrefKey, mode.index);
    notifyListeners();
  }

  Future<void> setDailyNewCardLimit(int limit) async {
    _dailyNewCardLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.dailyNewCardLimitPrefKey, limit);
    notifyListeners();
  }

  Future<void> setDailyReviewLimit(int limit) async {
    _dailyReviewLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.dailyReviewLimitPrefKey, limit);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.notificationsEnabledPrefKey, enabled);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.reminderTimePrefKey,
      '${time.hour}:${time.minute}',
    );
    notifyListeners();
  }

  Future<void> setNewCardsPerDay(int count) async {
    _newCardsPerDay = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('newCardsPerDay', count);
    notifyListeners();
  }

  Future<void> setReviewsPerDay(int count) async {
    _reviewsPerDay = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reviewsPerDay', count);
    notifyListeners();
  }

  Future<void> setCardDirectionMode(String mode) async {
    _cardDirectionMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cardDirectionMode', mode);
    notifyListeners();
  }
}

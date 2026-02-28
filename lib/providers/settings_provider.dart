import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyThemeMode = 'theme_mode';
  static const _keyReminderHour = 'reminder_hour';
  static const _keyReminderMinute = 'reminder_minute';
  static const _keySoundEnabled = 'sound_enabled';

  ThemeMode _themeMode = ThemeMode.system;
  int _reminderHour = 18;
  int _reminderMinute = 0;
  bool _soundEnabled = true;

  ThemeMode get themeMode => _themeMode;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  bool get soundEnabled => _soundEnabled;
  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _reminderHour, minute: _reminderMinute);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = ThemeMode.values[
        prefs.getInt(_keyThemeMode) ?? ThemeMode.system.index];
    _reminderHour = prefs.getInt(_keyReminderHour) ?? 18;
    _reminderMinute = prefs.getInt(_keyReminderMinute) ?? 0;
    _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour;
    _reminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, enabled);
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../database/hive_database.dart';

/// Provider for the HiveDatabase singleton.
final hiveDatabaseProvider = Provider<HiveDatabase>((ref) => HiveDatabase());

/// Notifier that manages the app's ThemeMode.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  final HiveDatabase _db;

  ThemeNotifier(this._db) : super(_loadTheme(_db));

  static ThemeMode _loadTheme(HiveDatabase db) {
    final value = db.getSetting<String>(AppConstants.themeKey, 'system');
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _db.setSetting(AppConstants.themeKey, mode.name);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }
}

/// Provider for the ThemeNotifier.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(ref.read(hiveDatabaseProvider)),
);

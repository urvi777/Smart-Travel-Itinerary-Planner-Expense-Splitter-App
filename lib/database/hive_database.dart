import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

/// Manages all Hive database operations.
/// Provides type-safe box access and handles initialization.
class HiveDatabase {
  static final HiveDatabase _instance = HiveDatabase._internal();
  factory HiveDatabase() => _instance;
  HiveDatabase._internal();

  bool _isInitialized = false;

  /// Initialize Hive and open all required boxes.
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    // Open all boxes — using dynamic maps for flexible schema
    await Future.wait([
      Hive.openBox<Map>(AppConstants.tripsBox),
      Hive.openBox<Map>(AppConstants.itineraryBox),
      Hive.openBox<Map>(AppConstants.expensesBox),
      Hive.openBox<Map>(AppConstants.syncQueueBox),
      Hive.openBox(AppConstants.settingsBox),
    ]);

    _isInitialized = true;
  }

  /// Get the trips box.
  Box<Map> get tripsBox => Hive.box<Map>(AppConstants.tripsBox);

  /// Get the itinerary items box.
  Box<Map> get itineraryBox => Hive.box<Map>(AppConstants.itineraryBox);

  /// Get the expenses box.
  Box<Map> get expensesBox => Hive.box<Map>(AppConstants.expensesBox);

  /// Get the sync queue box.
  Box<Map> get syncQueueBox => Hive.box<Map>(AppConstants.syncQueueBox);

  /// Get the settings box (stores primitives).
  Box get settingsBox => Hive.box(AppConstants.settingsBox);

  /// Read a setting value with a default fallback.
  T getSetting<T>(String key, T defaultValue) {
    try {
      return settingsBox.get(key, defaultValue: defaultValue) as T;
    } catch (_) {
      return defaultValue;
    }
  }

  /// Write a setting value.
  Future<void> setSetting(String key, dynamic value) async {
    try {
      await settingsBox.put(key, value);
    } catch (e) {
      // Silently fail — settings are non-critical
    }
  }

  /// Close all boxes (for cleanup).
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}

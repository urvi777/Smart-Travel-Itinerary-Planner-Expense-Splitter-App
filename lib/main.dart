import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/hive_database.dart';
import 'app.dart';

/// Application entry point.
///
/// Initializes Hive database before launching the app with Riverpod.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the local database
  try {
    await HiveDatabase().init();
  } catch (e) {
    debugPrint('Hive initialization error: $e');
    // App can still run — individual box operations will handle errors
  }

  runApp(
    const ProviderScope(
      child: TripMateApp(),
    ),
  );
}

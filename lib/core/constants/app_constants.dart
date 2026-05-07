/// Core constants used throughout the application.
class AppConstants {
  AppConstants._();

  static const String appName = 'TripMate';
  static const String appTagline = 'Plan. Split. Travel.';
  static const String appVersion = '1.0.0';
  static const String currencySymbol = '₹';

  // Hive box names
  static const String tripsBox = 'trips';
  static const String itineraryBox = 'itinerary_items';
  static const String expensesBox = 'expenses';
  static const String syncQueueBox = 'sync_queue';
  static const String settingsBox = 'settings';

  // Settings keys
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';
  static const String userNameKey = 'user_name';

  // Breakpoints for responsive design
  static const double phoneBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  // Animation durations
  static const Duration shortAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 400);
  static const Duration longAnim = Duration(milliseconds: 800);
}

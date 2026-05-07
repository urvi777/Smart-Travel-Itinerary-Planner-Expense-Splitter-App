import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/trip/create_trip_screen.dart';
import '../screens/trip/trip_details_screen.dart';
import '../screens/itinerary/itinerary_screen.dart';
import '../screens/expense/expense_entry_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Application router using go_router for declarative navigation.
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/trip/create',
      builder: (context, state) => const CreateTripScreen(),
    ),
    GoRoute(
      path: '/trip/:id',
      builder: (context, state) => TripDetailsScreen(
        tripId: state.pathParameters['id']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => CreateTripScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'itinerary',
          builder: (context, state) => ItineraryScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'expense/add',
          builder: (context, state) => ExpenseEntryScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'expense/:expenseId',
          builder: (context, state) => ExpenseEntryScreen(
            tripId: state.pathParameters['id']!,
            expenseId: state.pathParameters['expenseId'],
          ),
        ),
        GoRoute(
          path: 'analytics',
          builder: (context, state) => AnalyticsScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Page not found: ${state.uri}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);

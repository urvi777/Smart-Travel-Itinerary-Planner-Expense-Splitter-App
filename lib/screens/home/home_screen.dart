import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/date_extensions.dart';
import '../../models/trip.dart';
import '../../database/hive_database.dart';
import '../../providers/trip_providers.dart';
import '../../providers/expense_providers.dart';
import '../../widgets/common_widgets.dart';

/// Main home dashboard screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripListProvider);
    final theme = Theme.of(context);
    final userName = HiveDatabase().getSetting<String>(AppConstants.userNameKey, 'Traveler');

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(tripListProvider.notifier).loadTrips();
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $userName! 👋',
                              style: theme.textTheme.headlineMedium,
                            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1, end: 0),
                            const SizedBox(height: 4),
                            Text(
                              'Where to next?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ).animate(delay: 200.ms).fadeIn(),
                          ],
                        ),
                      ),
                      // Search button
                      IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () => context.push('/search'),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Settings
                      IconButton(
                        icon: const Icon(Icons.settings_rounded),
                        onPressed: () => context.push('/settings'),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Quick Stats ──
              if (trips.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: _QuickStats(trips: trips, ref: ref),
                  ),
                ),

              // ── Section Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Your Trips',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${trips.length} ${trips.length == 1 ? 'trip' : 'trips'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Trip List or Empty State ──
              if (trips.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.flight_takeoff_rounded,
                    title: 'No trips yet',
                    subtitle: 'Start planning your first adventure!\nTap + to create a new trip.',
                    actionLabel: 'Create Trip',
                    onAction: () => context.push('/trip/create'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final trip = trips[index];
                        return _TripCard(trip: trip)
                            .animate(delay: Duration(milliseconds: 100 * index))
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                      childCount: trips.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trip/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Trip'),
      ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }
}

/// Quick stats overview row at the top of the dashboard.
class _QuickStats extends StatelessWidget {
  final List trips;
  final WidgetRef ref;

  const _QuickStats({required this.trips, required this.ref});

  @override
  Widget build(BuildContext context) {
    final activeTrips = trips.where((t) => t.isOngoing || t.isUpcoming).length;
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.flight_takeoff,
            label: 'Total Trips',
            value: '${trips.length}',
            color: const Color(0xFF0D9488),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.explore,
            label: 'Active',
            value: '$activeTrips',
            color: const Color(0xFFFF8F00),
          ),
        ),
      ],
    );
  }
}

/// A premium trip card for the home screen list.
class _TripCard extends ConsumerWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expenses = ref.watch(expenseProvider(trip.id));
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);

    // Gradient colors based on trip state
    final gradientColors = trip.isOngoing
        ? [const Color(0xFF0D9488), const Color(0xFF06B6D4)]
        : trip.isUpcoming
            ? [const Color(0xFF7C3AED), const Color(0xFFDB2777)]
            : [const Color(0xFF64748B), const Color(0xFF475569)];

    return GestureDetector(
      onTap: () => context.push('/trip/${trip.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.cardTheme.color,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            // Top gradient bar with trip info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(colors: gradientColors),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trip.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          trip.isOngoing
                              ? 'Ongoing'
                              : trip.isUpcoming
                                  ? 'Upcoming'
                                  : 'Completed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        trip.destination,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today,
                    text: '${trip.startDate.shortFormatted} - ${trip.endDate.shortFormatted}',
                  ),
                  const Spacer(),
                  _InfoChip(
                    icon: Icons.people,
                    text: '${trip.participants.length}',
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.account_balance_wallet,
                    text: '${AppConstants.currencySymbol}${totalExpense.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

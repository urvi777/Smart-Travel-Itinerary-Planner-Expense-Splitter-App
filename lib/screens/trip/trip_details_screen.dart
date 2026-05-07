import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/date_extensions.dart';
import '../../models/trip.dart';
import '../../providers/trip_providers.dart';
import '../../providers/expense_providers.dart';
import '../../providers/itinerary_providers.dart';
import '../../widgets/common_widgets.dart';

/// Trip details screen with tabbed view: Overview, Itinerary, Expenses, Settlements.
class TripDetailsScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _deleteTrip(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text(
          'This will delete the trip and all its itinerary items and expenses. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // ignore: use_build_context_synchronously
      final router = GoRouter.of(context);
      await ref.read(tripListProvider.notifier).deleteTrip(widget.tripId);
      if (mounted) router.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripByIdProvider(widget.tripId));
    final theme = Theme.of(context);

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Trip not found')),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                trip.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: trip.isOngoing
                        ? [const Color(0xFF0D9488), const Color(0xFF06B6D4)]
                        : trip.isUpcoming
                            ? [const Color(0xFF7C3AED), const Color(0xFFDB2777)]
                            : [const Color(0xFF64748B), const Color(0xFF475569)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.flight, size: 40, color: Colors.white54),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/trip/${trip.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteTrip(context),
              ),
            ],
          ),
          SliverPersistentHeader(
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard, size: 20), text: 'Overview'),
                  Tab(icon: Icon(Icons.schedule, size: 20), text: 'Itinerary'),
                  Tab(icon: Icon(Icons.receipt, size: 20), text: 'Expenses'),
                  Tab(icon: Icon(Icons.handshake, size: 20), text: 'Settle'),
                ],
              ),
              theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(trip: trip),
            _ItineraryTab(trip: trip),
            _ExpensesTab(trip: trip),
            _SettlementsTab(trip: trip),
          ],
        ),
      ),
    );
  }
}

// ── Tab Bar Delegate ──
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;

  _TabBarDelegate(this.tabBar, this.bgColor);

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(color: bgColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ── Overview Tab ──
class _OverviewTab extends ConsumerWidget {
  final Trip trip;

  const _OverviewTab({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseProvider(trip.id));
    final itinerary = ref.watch(itineraryProvider(trip.id));
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.startDate.mediumFormatted} → ${trip.endDate.mediumFormatted}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text('${trip.durationDays} days', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                icon: Icons.account_balance_wallet,
                label: 'Total Expenses',
                value: '${AppConstants.currencySymbol}${totalExpense.toStringAsFixed(0)}',
                color: const Color(0xFFFF6B6B),
              ),
              StatCard(
                icon: Icons.people,
                label: 'Participants',
                value: '${trip.participants.length}',
                color: const Color(0xFF4ECDC4),
              ),
              StatCard(
                icon: Icons.schedule,
                label: 'Activities',
                value: '${itinerary.length}',
                color: const Color(0xFF45B7D1),
              ),
              StatCard(
                icon: Icons.receipt_long,
                label: 'Expenses',
                value: '${expenses.length}',
                color: const Color(0xFFFFD93D),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Participants section
          Text('Participants', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (trip.participants.isEmpty)
            _EmptyParticipants(tripId: trip.id)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trip.participants.map((p) {
                return Chip(
                  avatar: ParticipantAvatar(name: p.name, color: p.avatarColor, radius: 14),
                  label: Text(p.name),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _addParticipantDialog(context, ref, trip.id),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Add Participant'),
          ),

          if (trip.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Description', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(trip.description, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  void _addParticipantDialog(BuildContext context, WidgetRef ref, String tripId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Participant'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Participant name'),
          onSubmitted: (value) async {
            if (value.trim().isNotEmpty) {
              try {
                await ref.read(tripListProvider.notifier).addParticipant(tripId, value.trim());
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              }
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await ref.read(tripListProvider.notifier).addParticipant(tripId, controller.text.trim());
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _EmptyParticipants extends StatelessWidget {
  final String tripId;

  const _EmptyParticipants({required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 40, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text('No participants yet', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── Itinerary Tab ──
class _ItineraryTab extends ConsumerWidget {
  final Trip trip;

  const _ItineraryTab({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itineraryProvider(trip.id));
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.schedule,
        title: 'No itinerary yet',
        subtitle: 'Plan your daily activities',
        actionLabel: 'Add Activity',
        onAction: () => context.push('/trip/${trip.id}/itinerary'),
      );
    }

    // Group by date
    final grouped = <DateTime, List<dynamic>>{};
    for (final item in items) {
      final key = DateTime(item.date.year, item.date.month, item.date.day);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final dayItems = grouped[date]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day ${index + 1} · ${date.mediumFormatted}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Timeline items
                ...dayItems.map((item) => _TimelineItem(item: item, tripId: trip.id)),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'itinerary_fab',
            onPressed: () => context.push('/trip/${trip.id}/itinerary'),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends ConsumerWidget {
  final dynamic item;
  final String tripId;

  const _TimelineItem({required this.item, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline connector
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (item.time != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(item.time!, style: theme.textTheme.labelSmall),
                          ),
                        PopupMenuButton<String>(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                          onSelected: (value) {
                            if (value == 'delete') {
                              ref.read(itineraryProvider(tripId).notifier).deleteItem(item.id);
                            }
                          },
                          icon: Icon(Icons.more_vert, size: 18,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.description, style: theme.textTheme.bodySmall),
                    ],
                    if (item.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(item.location!, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expenses Tab ──
class _ExpensesTab extends ConsumerWidget {
  final Trip trip;

  const _ExpensesTab({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseProvider(trip.id));
    final theme = Theme.of(context);

    if (expenses.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'No expenses yet',
        subtitle: 'Start tracking your trip spending',
        actionLabel: 'Add Expense',
        onAction: () => context.push('/trip/${trip.id}/expense/add'),
      );
    }

    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Total banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Expenses',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppConstants.currencySymbol}${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        '${expenses.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const Text('entries', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Analytics button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/trip/${trip.id}/analytics'),
                    icon: const Icon(Icons.pie_chart, size: 18),
                    label: const Text('Analytics'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Expense list
            ...expenses.map((expense) {
              final payer = trip.participants.where((p) => p.id == expense.paidBy).firstOrNull;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  leading: CategoryIconWidget(
                    icon: expense.category.icon,
                    color: expense.category.color,
                  ),
                  title: Text(expense.description, style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    'Paid by ${payer?.name ?? 'Unknown'} · ${expense.dateTime.day}/${expense.dateTime.month}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Text(
                    '${AppConstants.currencySymbol}${expense.amount.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  onTap: () => context.push('/trip/${trip.id}/expense/${expense.id}'),
                ),
              );
            }),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'expense_fab',
            onPressed: () => context.push('/trip/${trip.id}/expense/add'),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── Settlements Tab ──
class _SettlementsTab extends ConsumerWidget {
  final Trip trip;

  const _SettlementsTab({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlements = ref.watch(settlementsProvider(trip.id));
    final balances = ref.watch(balancesProvider(trip.id));
    final theme = Theme.of(context);

    if (settlements.isEmpty && balances.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.handshake,
        title: 'All settled up!',
        subtitle: 'No pending settlements. Add expenses to see who owes whom.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balances
        Text('Net Balances', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        ...trip.participants.map((p) {
          final balance = balances[p.id] ?? 0;
          final isPositive = balance >= 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                ParticipantAvatar(name: p.name, color: p.avatarColor),
                const SizedBox(width: 12),
                Expanded(child: Text(p.name, style: theme.textTheme.titleSmall)),
                Text(
                  '${isPositive ? '+' : ''}${AppConstants.currencySymbol}${balance.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        }),

        if (settlements.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Settlements', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Simplified transactions to settle all debts',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ...settlements.map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  ParticipantAvatar(
                    name: s.fromName,
                    color: const Color(0xFFFF6B6B),
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.fromName, style: theme.textTheme.titleSmall),
                        Text('pays', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.arrow_forward, size: 20),
                      Text(
                        '${AppConstants.currencySymbol}${s.amount.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(s.toName, style: theme.textTheme.titleSmall),
                        Text('receives', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ParticipantAvatar(
                    name: s.toName,
                    color: const Color(0xFF4ECDC4),
                    radius: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

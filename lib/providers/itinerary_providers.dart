import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_database.dart';
import '../models/itinerary_item.dart';
import '../repositories/itinerary_repository.dart';

const _uuid = Uuid();

/// Notifier that manages itinerary items for a specific trip.
class ItineraryNotifier extends StateNotifier<List<ItineraryItem>> {
  final ItineraryRepository _repo;
  final String tripId;

  ItineraryNotifier(this._repo, this.tripId) : super([]) {
    loadItems();
  }

  /// Load all items for this trip from local storage.
  void loadItems() {
    try {
      state = _repo.getItemsByTripId(tripId);
    } catch (e) {
      state = [];
    }
  }

  /// Add a new itinerary item.
  Future<void> addItem({
    required DateTime date,
    required String title,
    String description = '',
    String? time,
    String? location,
    String? notes,
  }) async {
    final existingItems = _repo.getItemsByDate(tripId, date);
    final item = ItineraryItem(
      id: _uuid.v4(),
      tripId: tripId,
      date: DateTime(date.year, date.month, date.day),
      title: title,
      description: description,
      time: time,
      location: location,
      notes: notes,
      order: existingItems.length,
    );

    await _repo.saveItem(item);
    loadItems();
  }

  /// Update an existing itinerary item.
  Future<void> updateItem(ItineraryItem item) async {
    await _repo.saveItem(item);
    loadItems();
  }

  /// Delete an itinerary item.
  Future<void> deleteItem(String id) async {
    await _repo.deleteItem(id);
    loadItems();
  }

  /// Get items grouped by date.
  Map<DateTime, List<ItineraryItem>> get groupedByDate {
    final grouped = <DateTime, List<ItineraryItem>>{};
    for (final item in state) {
      final dateKey = DateTime(item.date.year, item.date.month, item.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

/// Family provider for itinerary items per trip.
final itineraryProvider = StateNotifierProvider.family<ItineraryNotifier, List<ItineraryItem>, String>(
  (ref, tripId) => ItineraryNotifier(
    ItineraryRepository(HiveDatabase()),
    tripId,
  ),
);

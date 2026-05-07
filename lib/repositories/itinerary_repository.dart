import '../database/hive_database.dart';
import '../models/itinerary_item.dart';

/// Repository for itinerary item CRUD operations using Hive local storage.
class ItineraryRepository {
  final HiveDatabase _db;

  ItineraryRepository(this._db);

  /// Get all itinerary items for a specific trip, sorted by date then order.
  List<ItineraryItem> getItemsByTripId(String tripId) {
    try {
      final box = _db.itineraryBox;
      final items = box.values
          .map((data) => ItineraryItem.fromJson(data))
          .where((item) => item.tripId == tripId)
          .toList()
        ..sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          return a.order.compareTo(b.order);
        });
      return items;
    } catch (e) {
      return [];
    }
  }

  /// Get items for a specific date within a trip.
  List<ItineraryItem> getItemsByDate(String tripId, DateTime date) {
    return getItemsByTripId(tripId).where((item) {
      return item.date.year == date.year &&
          item.date.month == date.month &&
          item.date.day == date.day;
    }).toList();
  }

  /// Save (create or update) an itinerary item.
  Future<void> saveItem(ItineraryItem item) async {
    try {
      await _db.itineraryBox.put(item.id, item.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an itinerary item.
  Future<void> deleteItem(String id) async {
    try {
      await _db.itineraryBox.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all items for a trip (used when deleting a trip).
  Future<void> deleteAllForTrip(String tripId) async {
    try {
      final items = getItemsByTripId(tripId);
      for (final item in items) {
        await _db.itineraryBox.delete(item.id);
      }
    } catch (e) {
      // Best-effort cleanup
    }
  }

  /// Count of itinerary items for a trip.
  int countForTrip(String tripId) {
    return getItemsByTripId(tripId).length;
  }
}

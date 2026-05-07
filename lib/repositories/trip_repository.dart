import '../database/hive_database.dart';
import '../models/trip.dart';

/// Repository for Trip CRUD operations using Hive local storage.
class TripRepository {
  final HiveDatabase _db;

  TripRepository(this._db);

  /// Get all trips, sorted by most recently updated.
  List<Trip> getAllTrips() {
    try {
      final box = _db.tripsBox;
      final trips = box.values
          .map((data) => Trip.fromJson(data))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return trips;
    } catch (e) {
      return [];
    }
  }

  /// Get a single trip by ID.
  Trip? getTripById(String id) {
    try {
      final data = _db.tripsBox.get(id);
      if (data == null) return null;
      return Trip.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Create or update a trip.
  Future<void> saveTrip(Trip trip) async {
    try {
      await _db.tripsBox.put(trip.id, trip.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a trip by ID.
  Future<void> deleteTrip(String id) async {
    try {
      await _db.tripsBox.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Search trips by name or destination.
  List<Trip> searchTrips(String query) {
    if (query.isEmpty) return getAllTrips();
    final q = query.toLowerCase();
    return getAllTrips().where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.destination.toLowerCase().contains(q);
    }).toList();
  }
}

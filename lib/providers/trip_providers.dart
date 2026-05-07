import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/hive_database.dart';
import '../models/trip.dart';
import '../models/participant.dart';
import '../repositories/trip_repository.dart';
import '../repositories/itinerary_repository.dart';
import '../repositories/expense_repository.dart';

const _uuid = Uuid();

/// Provider for TripRepository.
final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepository(HiveDatabase()),
);

/// Provider for ItineraryRepository.
final itineraryRepositoryProvider = Provider<ItineraryRepository>(
  (ref) => ItineraryRepository(HiveDatabase()),
);

/// Provider for ExpenseRepository.
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(HiveDatabase()),
);

/// Notifier that manages the list of all trips.
class TripListNotifier extends StateNotifier<List<Trip>> {
  final TripRepository _repo;
  final ItineraryRepository _itineraryRepo;
  final ExpenseRepository _expenseRepo;

  TripListNotifier(this._repo, this._itineraryRepo, this._expenseRepo)
      : super([]) {
    loadTrips();
  }

  /// Load all trips from local storage.
  void loadTrips() {
    try {
      state = _repo.getAllTrips();
    } catch (e) {
      state = [];
    }
  }

  /// Create a new trip.
  Future<Trip> createTrip({
    required String name,
    required String destination,
    String description = '',
    required DateTime startDate,
    required DateTime endDate,
    String? coverImage,
    List<String> participantNames = const [],
  }) async {
    final participants = participantNames
        .map((name) => Participant(id: _uuid.v4(), name: name))
        .toList();

    final trip = Trip(
      id: _uuid.v4(),
      name: name,
      destination: destination,
      description: description,
      startDate: startDate,
      endDate: endDate,
      coverImage: coverImage,
      participants: participants,
    );

    await _repo.saveTrip(trip);
    loadTrips();
    return trip;
  }

  /// Update an existing trip.
  Future<void> updateTrip(Trip trip) async {
    await _repo.saveTrip(trip);
    loadTrips();
  }

  /// Delete a trip and all associated data.
  Future<void> deleteTrip(String tripId) async {
    await _itineraryRepo.deleteAllForTrip(tripId);
    await _expenseRepo.deleteAllForTrip(tripId);
    await _repo.deleteTrip(tripId);
    loadTrips();
  }

  /// Add a participant to a trip.
  Future<void> addParticipant(String tripId, String name) async {
    final trip = _repo.getTripById(tripId);
    if (trip == null) return;

    // Prevent duplicate names
    if (trip.participants.any(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    )) {
      throw Exception('Participant "$name" already exists');
    }

    final updated = trip.copyWith(
      participants: [
        ...trip.participants,
        Participant(id: _uuid.v4(), name: name),
      ],
    );
    await _repo.saveTrip(updated);
    loadTrips();
  }

  /// Remove a participant from a trip.
  Future<void> removeParticipant(String tripId, String participantId) async {
    final trip = _repo.getTripById(tripId);
    if (trip == null) return;

    final updated = trip.copyWith(
      participants: trip.participants
          .where((p) => p.id != participantId)
          .toList(),
    );
    await _repo.saveTrip(updated);
    loadTrips();
  }

  /// Search trips by name or destination.
  List<Trip> searchTrips(String query) {
    return _repo.searchTrips(query);
  }
}

/// Provider for the trip list notifier.
final tripListProvider = StateNotifierProvider<TripListNotifier, List<Trip>>(
  (ref) => TripListNotifier(
    ref.read(tripRepositoryProvider),
    ref.read(itineraryRepositoryProvider),
    ref.read(expenseRepositoryProvider),
  ),
);

/// Provider for a single trip by ID.
final tripByIdProvider = Provider.family<Trip?, String>((ref, id) {
  final trips = ref.watch(tripListProvider);
  try {
    return trips.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
});

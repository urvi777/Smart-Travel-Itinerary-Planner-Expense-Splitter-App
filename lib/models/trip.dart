import 'participant.dart';

/// Represents a travel trip with participants and metadata.
class Trip {
  final String id;
  final String name;
  final String destination;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImage;
  final List<Participant> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.name,
    required this.destination,
    this.description = '',
    required this.startDate,
    required this.endDate,
    this.coverImage,
    List<Participant>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : participants = participants ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Total duration of the trip in days (inclusive).
  int get durationDays => endDate.difference(startDate).inDays + 1;

  /// Whether the trip is currently ongoing.
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Whether the trip is in the future.
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  /// Whether the trip has ended.
  bool get isPast => DateTime.now().isAfter(endDate);

  /// All dates within the trip range for itinerary planning.
  List<DateTime> get allDates {
    final dates = <DateTime>[];
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    while (!current.isAfter(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'destination': destination,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'coverImage': coverImage,
        'participants': participants.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Trip.fromJson(Map<dynamic, dynamic> json) {
    return Trip(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      coverImage: json['coverImage'] as String?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => Participant.fromJson(p as Map<dynamic, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Trip copyWith({
    String? name,
    String? destination,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImage,
    List<Participant>? participants,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImage: coverImage ?? this.coverImage,
      participants: participants ?? this.participants,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

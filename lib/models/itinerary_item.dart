/// Represents a single activity in a trip's itinerary.
class ItineraryItem {
  final String id;
  final String tripId;
  final DateTime date;
  final String title;
  final String description;
  final String? time; // HH:mm format string
  final String? location;
  final String? notes;
  final int order; // Sort order within a day

  ItineraryItem({
    required this.id,
    required this.tripId,
    required this.date,
    required this.title,
    this.description = '',
    this.time,
    this.location,
    this.notes,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'date': date.toIso8601String(),
        'title': title,
        'description': description,
        'time': time,
        'location': location,
        'notes': notes,
        'order': order,
      };

  factory ItineraryItem.fromJson(Map<dynamic, dynamic> json) {
    return ItineraryItem(
      id: json['id'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      time: json['time'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  ItineraryItem copyWith({
    DateTime? date,
    String? title,
    String? description,
    String? time,
    String? location,
    String? notes,
    int? order,
  }) {
    return ItineraryItem(
      id: id,
      tripId: tripId,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

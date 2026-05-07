import 'package:flutter/material.dart';

/// Represents a trip participant.
class Participant {
  final String id;
  final String name;
  final String? email;

  /// Deterministic avatar color derived from participant's name hash.
  final int avatarColorValue;

  Participant({
    required this.id,
    required this.name,
    this.email,
    int? avatarColorValue,
  }) : avatarColorValue = avatarColorValue ?? _generateColor(name);

  /// Generate a consistent color value from the name hash.
  static int _generateColor(String name) {
    final colors = [
      const Color(0xFFFF6B6B).toARGB32(),
      const Color(0xFF4ECDC4).toARGB32(),
      const Color(0xFF45B7D1).toARGB32(),
      const Color(0xFFFFA07A).toARGB32(),
      const Color(0xFF98D8C8).toARGB32(),
      const Color(0xFFDDA0DD).toARGB32(),
      const Color(0xFFFFD93D).toARGB32(),
      const Color(0xFF6BCB77).toARGB32(),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Color get avatarColor => Color(avatarColorValue);

  /// First letter of name, upper-cased, for avatar display.
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarColorValue': avatarColorValue,
      };

  factory Participant.fromJson(Map<dynamic, dynamic> json) {
    return Participant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String?,
      avatarColorValue: json['avatarColorValue'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Participant copyWith({String? name, String? email}) {
    return Participant(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarColorValue: avatarColorValue,
    );
  }
}

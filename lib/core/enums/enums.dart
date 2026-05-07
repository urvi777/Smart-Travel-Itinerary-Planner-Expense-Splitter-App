import 'package:flutter/material.dart';

/// Enum representing expense categories with associated icons and colors.
enum ExpenseCategory {
  food(Icons.restaurant, Color(0xFFFF6B6B), 'Food'),
  hotel(Icons.hotel, Color(0xFF4ECDC4), 'Hotel'),
  transport(Icons.directions_car, Color(0xFF45B7D1), 'Transport'),
  tickets(Icons.confirmation_number, Color(0xFFFFA07A), 'Tickets'),
  shopping(Icons.shopping_bag, Color(0xFFDDA0DD), 'Shopping'),
  other(Icons.more_horiz, Color(0xFF98D8C8), 'Other');

  final IconData icon;
  final Color color;
  final String label;

  const ExpenseCategory(this.icon, this.color, this.label);

  /// Safely parse a category from a string, defaulting to [other].
  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// Enum representing how an expense is split among participants.
enum SplitType {
  equal('Equal Split'),
  custom('Custom Split');

  final String label;
  const SplitType(this.label);

  static SplitType fromString(String value) {
    return SplitType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SplitType.equal,
    );
  }
}

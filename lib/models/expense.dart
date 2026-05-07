import '../core/enums/enums.dart';

/// Represents an expense within a trip, tracking who paid and how it is split.
class Expense {
  final String id;
  final String tripId;
  final double amount;
  final String description;
  final ExpenseCategory category;
  final String paidBy; // Participant ID
  final SplitType splitType;
  final List<String> splitAmong; // List of participant IDs
  /// Custom amounts per participant (only used when splitType == custom).
  /// Key: participant ID, Value: custom amount.
  final Map<String, double>? customSplitAmounts;
  final DateTime dateTime;
  final String? notes;

  Expense({
    required this.id,
    required this.tripId,
    required this.amount,
    required this.description,
    this.category = ExpenseCategory.other,
    required this.paidBy,
    this.splitType = SplitType.equal,
    required this.splitAmong,
    this.customSplitAmounts,
    DateTime? dateTime,
    this.notes,
  }) : dateTime = dateTime ?? DateTime.now();

  /// Compute each participant's share for this expense.
  Map<String, double> getShares() {
    if (splitAmong.isEmpty) return {};

    if (splitType == SplitType.custom && customSplitAmounts != null) {
      return Map<String, double>.from(customSplitAmounts!);
    }

    // Equal split — divide evenly among participants
    final share = amount / splitAmong.length;
    return {for (final pid in splitAmong) pid: share};
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'amount': amount,
        'description': description,
        'category': category.name,
        'paidBy': paidBy,
        'splitType': splitType.name,
        'splitAmong': splitAmong,
        'customSplitAmounts': customSplitAmounts,
        'dateTime': dateTime.toIso8601String(),
        'notes': notes,
      };

  factory Expense.fromJson(Map<dynamic, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      tripId: json['tripId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      category: ExpenseCategory.fromString(json['category'] as String? ?? 'other'),
      paidBy: json['paidBy'] as String? ?? '',
      splitType: SplitType.fromString(json['splitType'] as String? ?? 'equal'),
      splitAmong: (json['splitAmong'] as List<dynamic>?)?.cast<String>() ?? [],
      customSplitAmounts: (json['customSplitAmounts'] as Map<dynamic, dynamic>?)
          ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      dateTime: DateTime.tryParse(json['dateTime'] as String? ?? '') ?? DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  Expense copyWith({
    double? amount,
    String? description,
    ExpenseCategory? category,
    String? paidBy,
    SplitType? splitType,
    List<String>? splitAmong,
    Map<String, double>? customSplitAmounts,
    DateTime? dateTime,
    String? notes,
  }) {
    return Expense(
      id: id,
      tripId: tripId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      splitType: splitType ?? this.splitType,
      splitAmong: splitAmong ?? this.splitAmong,
      customSplitAmounts: customSplitAmounts ?? this.customSplitAmounts,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

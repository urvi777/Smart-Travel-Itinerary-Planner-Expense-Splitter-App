/// Represents a simplified settlement between two participants.
/// [fromId] should pay [toId] the specified [amount].
class Settlement {
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;

  const Settlement({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });

  @override
  String toString() => '$fromName owes $toName ₹${amount.toStringAsFixed(2)}';
}

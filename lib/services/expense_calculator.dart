import '../models/expense.dart';
import '../models/participant.dart';
import '../models/settlement.dart';

/// Service that handles all expense calculation and settlement logic.
///
/// Uses a greedy debt-simplification algorithm to minimize the number
/// of transactions needed to settle all balances.
class ExpenseCalculator {
  /// Calculate the net balance for each participant across all [expenses].
  ///
  /// Positive balance = participant is owed money (paid more than their share).
  /// Negative balance = participant owes money (paid less than their share).
  Map<String, double> calculateBalances(List<Expense> expenses) {
    final balances = <String, double>{};

    for (final expense in expenses) {
      final shares = expense.getShares();

      // The payer's balance increases by the amount they paid
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amount;

      // Each participant's balance decreases by their share
      for (final entry in shares.entries) {
        balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
      }
    }

    return balances;
  }

  /// Calculate total paid by each participant.
  Map<String, double> calculateTotalPaid(List<Expense> expenses) {
    final paid = <String, double>{};
    for (final expense in expenses) {
      paid[expense.paidBy] = (paid[expense.paidBy] ?? 0) + expense.amount;
    }
    return paid;
  }

  /// Calculate total owed by each participant (sum of their shares).
  Map<String, double> calculateTotalOwed(List<Expense> expenses) {
    final owed = <String, double>{};
    for (final expense in expenses) {
      final shares = expense.getShares();
      for (final entry in shares.entries) {
        owed[entry.key] = (owed[entry.key] ?? 0) + entry.value;
      }
    }
    return owed;
  }

  /// Compute simplified settlements using a greedy algorithm.
  ///
  /// This algorithm minimizes the number of transactions:
  /// 1. Calculate net balances for all participants.
  /// 2. Separate into creditors (positive balance) and debtors (negative balance).
  /// 3. Match the largest debtor with the largest creditor repeatedly.
  List<Settlement> calculateSettlements(
    List<Expense> expenses,
    List<Participant> participants,
  ) {
    if (expenses.isEmpty || participants.isEmpty) return [];

    final balances = calculateBalances(expenses);
    final participantMap = {for (final p in participants) p.id: p};

    // Separate into creditors and debtors
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    for (final entry in balances.entries) {
      // Round to avoid floating-point noise
      final rounded = double.parse(entry.value.toStringAsFixed(2));
      if (rounded > 0.01) {
        creditors.add(MapEntry(entry.key, rounded));
      } else if (rounded < -0.01) {
        debtors.add(MapEntry(entry.key, rounded.abs()));
      }
    }

    // Sort both lists descending by amount for optimal matching
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final settlements = <Settlement>[];

    // Greedy matching: pair largest debtor with largest creditor
    int ci = 0, di = 0;
    final cAmounts = creditors.map((e) => e.value).toList();
    final dAmounts = debtors.map((e) => e.value).toList();

    while (ci < creditors.length && di < debtors.length) {
      final amount = cAmounts[ci] < dAmounts[di] ? cAmounts[ci] : dAmounts[di];

      if (amount > 0.01) {
        final fromId = debtors[di].key;
        final toId = creditors[ci].key;
        final fromP = participantMap[fromId];
        final toP = participantMap[toId];

        settlements.add(Settlement(
          fromId: fromId,
          fromName: fromP?.name ?? 'Unknown',
          toId: toId,
          toName: toP?.name ?? 'Unknown',
          amount: double.parse(amount.toStringAsFixed(2)),
        ));
      }

      cAmounts[ci] -= amount;
      dAmounts[di] -= amount;

      if (cAmounts[ci] < 0.01) ci++;
      if (dAmounts[di] < 0.01) di++;
    }

    return settlements;
  }

  /// Get daily spending totals for charting.
  Map<DateTime, double> getDailySpending(List<Expense> expenses) {
    final daily = <DateTime, double>{};
    for (final expense in expenses) {
      final dateKey = DateTime(
        expense.dateTime.year,
        expense.dateTime.month,
        expense.dateTime.day,
      );
      daily[dateKey] = (daily[dateKey] ?? 0) + expense.amount;
    }
    return Map.fromEntries(
      daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}

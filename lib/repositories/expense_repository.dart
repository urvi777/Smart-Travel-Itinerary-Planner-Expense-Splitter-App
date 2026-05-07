import '../core/enums/enums.dart';
import '../database/hive_database.dart';
import '../models/expense.dart';

/// Repository for expense CRUD operations using Hive local storage.
class ExpenseRepository {
  final HiveDatabase _db;

  ExpenseRepository(this._db);

  /// Get all expenses for a specific trip, sorted by date (newest first).
  List<Expense> getExpensesByTripId(String tripId) {
    try {
      final box = _db.expensesBox;
      final expenses = box.values
          .map((data) => Expense.fromJson(data))
          .where((e) => e.tripId == tripId)
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return expenses;
    } catch (e) {
      return [];
    }
  }

  /// Save (create or update) an expense.
  Future<void> saveExpense(Expense expense) async {
    try {
      await _db.expensesBox.put(expense.id, expense.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an expense.
  Future<void> deleteExpense(String id) async {
    try {
      await _db.expensesBox.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all expenses for a trip (used when deleting a trip).
  Future<void> deleteAllForTrip(String tripId) async {
    try {
      final expenses = getExpensesByTripId(tripId);
      for (final expense in expenses) {
        await _db.expensesBox.delete(expense.id);
      }
    } catch (e) {
      // Best-effort cleanup
    }
  }

  /// Total amount of all expenses for a trip.
  double totalForTrip(String tripId) {
    return getExpensesByTripId(tripId).fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Filter expenses by category.
  List<Expense> filterByCategory(String tripId, ExpenseCategory category) {
    return getExpensesByTripId(tripId)
        .where((e) => e.category == category)
        .toList();
  }

  /// Filter expenses by payer.
  List<Expense> filterByPayer(String tripId, String payerId) {
    return getExpensesByTripId(tripId)
        .where((e) => e.paidBy == payerId)
        .toList();
  }

  /// Search expenses by description.
  List<Expense> searchExpenses(String tripId, String query) {
    if (query.isEmpty) return getExpensesByTripId(tripId);
    final q = query.toLowerCase();
    return getExpensesByTripId(tripId)
        .where((e) => e.description.toLowerCase().contains(q))
        .toList();
  }

  /// Get category-wise expense breakdown for a trip.
  Map<ExpenseCategory, double> getCategoryBreakdown(String tripId) {
    final expenses = getExpensesByTripId(tripId);
    final breakdown = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      breakdown[expense.category] =
          (breakdown[expense.category] ?? 0) + expense.amount;
    }
    return breakdown;
  }
}

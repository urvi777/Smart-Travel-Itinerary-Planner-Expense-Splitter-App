import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/enums/enums.dart';
import '../database/hive_database.dart';
import '../models/expense.dart';
import '../models/settlement.dart';
import '../repositories/expense_repository.dart';
import '../services/expense_calculator.dart';
import 'trip_providers.dart';

const _uuid = Uuid();

/// Notifier that manages expenses for a specific trip.
class ExpenseNotifier extends StateNotifier<List<Expense>> {
  final ExpenseRepository _repo;
  final String tripId;

  ExpenseNotifier(this._repo, this.tripId) : super([]) {
    loadExpenses();
  }

  /// Load all expenses for this trip.
  void loadExpenses() {
    try {
      state = _repo.getExpensesByTripId(tripId);
    } catch (e) {
      state = [];
    }
  }

  /// Add a new expense.
  Future<void> addExpense({
    required double amount,
    required String description,
    ExpenseCategory category = ExpenseCategory.other,
    required String paidBy,
    SplitType splitType = SplitType.equal,
    required List<String> splitAmong,
    Map<String, double>? customSplitAmounts,
    DateTime? dateTime,
    String? notes,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      tripId: tripId,
      amount: amount,
      description: description,
      category: category,
      paidBy: paidBy,
      splitType: splitType,
      splitAmong: splitAmong,
      customSplitAmounts: customSplitAmounts,
      dateTime: dateTime,
      notes: notes,
    );

    await _repo.saveExpense(expense);
    loadExpenses();
  }

  /// Update an existing expense.
  Future<void> updateExpense(Expense expense) async {
    await _repo.saveExpense(expense);
    loadExpenses();
  }

  /// Delete an expense.
  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    loadExpenses();
  }

  /// Get the total expense amount.
  double get totalAmount => state.fold(0.0, (sum, e) => sum + e.amount);

  /// Get category breakdown.
  Map<ExpenseCategory, double> get categoryBreakdown {
    return _repo.getCategoryBreakdown(tripId);
  }

  /// Search expenses.
  List<Expense> search(String query) {
    return _repo.searchExpenses(tripId, query);
  }

  /// Filter by category.
  List<Expense> filterByCategory(ExpenseCategory category) {
    return _repo.filterByCategory(tripId, category);
  }
}

/// Family provider for expenses per trip.
final expenseProvider = StateNotifierProvider.family<ExpenseNotifier, List<Expense>, String>(
  (ref, tripId) => ExpenseNotifier(
    ExpenseRepository(HiveDatabase()),
    tripId,
  ),
);

/// Provider for the expense calculator service.
final expenseCalculatorProvider = Provider((ref) => ExpenseCalculator());

/// Provider for settlements for a specific trip.
final settlementsProvider = Provider.family<List<Settlement>, String>((ref, tripId) {
  final expenses = ref.watch(expenseProvider(tripId));
  final trip = ref.watch(tripByIdProvider(tripId));
  if (trip == null) return [];
  final calculator = ref.read(expenseCalculatorProvider);
  return calculator.calculateSettlements(expenses, trip.participants);
});

/// Provider for participant balances for a specific trip.
final balancesProvider = Provider.family<Map<String, double>, String>((ref, tripId) {
  final expenses = ref.watch(expenseProvider(tripId));
  final calculator = ref.read(expenseCalculatorProvider);
  return calculator.calculateBalances(expenses);
});

/// Provider for total paid per participant.
final totalPaidProvider = Provider.family<Map<String, double>, String>((ref, tripId) {
  final expenses = ref.watch(expenseProvider(tripId));
  final calculator = ref.read(expenseCalculatorProvider);
  return calculator.calculateTotalPaid(expenses);
});

/// Provider for total owed per participant.
final totalOwedProvider = Provider.family<Map<String, double>, String>((ref, tripId) {
  final expenses = ref.watch(expenseProvider(tripId));
  final calculator = ref.read(expenseCalculatorProvider);
  return calculator.calculateTotalOwed(expenses);
});

/// Provider for daily spending data.
final dailySpendingProvider = Provider.family<Map<DateTime, double>, String>((ref, tripId) {
  final expenses = ref.watch(expenseProvider(tripId));
  final calculator = ref.read(expenseCalculatorProvider);
  return calculator.getDailySpending(expenses);
});

/// Provider for category breakdown.
final categoryBreakdownProvider = Provider.family<Map<ExpenseCategory, double>, String>((ref, tripId) {
  final expenses = ref.watch(expenseProvider(tripId));
  final breakdown = <ExpenseCategory, double>{};
  for (final e in expenses) {
    breakdown[e.category] = (breakdown[e.category] ?? 0) + e.amount;
  }
  return breakdown;
});

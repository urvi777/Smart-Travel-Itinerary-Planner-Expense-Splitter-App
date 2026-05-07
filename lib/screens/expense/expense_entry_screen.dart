import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';
import '../../providers/trip_providers.dart';
import '../../providers/expense_providers.dart';
import '../../widgets/common_widgets.dart';

/// Screen for adding or editing an expense.
class ExpenseEntryScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String? expenseId; // null = add, non-null = edit

  const ExpenseEntryScreen({super.key, required this.tripId, this.expenseId});

  @override
  ConsumerState<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends ConsumerState<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.other;
  String? _paidBy;
  SplitType _splitType = SplitType.equal;
  Set<String> _splitAmong = {};
  DateTime _dateTime = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final expenses = ref.read(expenseProvider(widget.tripId));
        final expense = expenses.where((e) => e.id == widget.expenseId).firstOrNull;
        if (expense != null) {
          _amountController.text = expense.amount.toStringAsFixed(2);
          _descriptionController.text = expense.description;
          _notesController.text = expense.notes ?? '';
          _category = expense.category;
          _paidBy = expense.paidBy;
          _splitType = expense.splitType;
          _splitAmong = Set.from(expense.splitAmong);
          _dateTime = expense.dateTime;
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_paidBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select who paid'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_splitAmong.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select participants to split with'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final expenses = ref.read(expenseProvider(widget.tripId));
        final expense = expenses.firstWhere((e) => e.id == widget.expenseId);
        await ref.read(expenseProvider(widget.tripId).notifier).updateExpense(
              expense.copyWith(
                amount: amount,
                description: _descriptionController.text.trim(),
                category: _category,
                paidBy: _paidBy,
                splitType: _splitType,
                splitAmong: _splitAmong.toList(),
                dateTime: _dateTime,
                notes: _notesController.text.trim().isNotEmpty
                    ? _notesController.text.trim()
                    : null,
              ),
            );
      } else {
        await ref.read(expenseProvider(widget.tripId).notifier).addExpense(
              amount: amount,
              description: _descriptionController.text.trim(),
              category: _category,
              paidBy: _paidBy!,
              splitType: _splitType,
              splitAmong: _splitAmong.toList(),
              dateTime: _dateTime,
              notes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Expense updated!' : 'Expense added!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripByIdProvider(widget.tripId));
    final theme = Theme.of(context);

    if (trip == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Trip not found')));
    }

    if (trip.participants.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Expense')),
        body: const EmptyStateWidget(
          icon: Icons.people,
          title: 'No participants',
          subtitle: 'Add participants to the trip before adding expenses.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Amount (large, prominent)
            Center(
              child: SizedBox(
                width: 200,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    prefixText: '${AppConstants.currencySymbol} ',
                    prefixStyle: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                    hintText: '0.00',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final amount = double.tryParse(v.trim());
                    if (amount == null) return 'Invalid number';
                    if (amount <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'e.g., Dinner at restaurant',
                prefixIcon: Icon(Icons.receipt),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter description';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Category grid
            Text('Category', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.4,
              children: ExpenseCategory.values.map((cat) {
                final isSelected = _category == cat;
                return InkWell(
                  onTap: () => setState(() => _category = cat),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? cat.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat.icon, color: cat.color, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Paid by
            Text('Paid By', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trip.participants.map((p) {
                final isSelected = _paidBy == p.id;
                return ChoiceChip(
                  label: Text(p.name),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _paidBy = p.id),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                  avatar: isSelected
                      ? null
                      : ParticipantAvatar(name: p.name, color: p.avatarColor, radius: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Split type
            Text('Split Type', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<SplitType>(
              segments: SplitType.values
                  .map((s) => ButtonSegment(value: s, label: Text(s.label)))
                  .toList(),
              selected: {_splitType},
              onSelectionChanged: (selected) {
                setState(() => _splitType = selected.first);
              },
            ),
            const SizedBox(height: 24),

            // Split among
            Row(
              children: [
                Text('Split Among', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _splitAmong = trip.participants.map((p) => p.id).toSet();
                    });
                  },
                  child: const Text('Select All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...trip.participants.map((p) {
              final isSelected = _splitAmong.contains(p.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _splitAmong.add(p.id);
                    } else {
                      _splitAmong.remove(p.id);
                    }
                  });
                },
                title: Text(p.name),
                secondary: ParticipantAvatar(name: p.name, color: p.avatarColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                dense: true,
              );
            }),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_isEditing ? Icons.save : Icons.check),
                label: Text(_isEditing ? 'Save Changes' : 'Add Expense'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../repository/shop_repository.dart';

const _kCategories = [
  'Electricity',
  'Rent',
  'Staff Wages',
  'Transport',
  'Repairs',
  'Misc',
];

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late Future<List<Expense>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _expensesFuture = context.read<ShopRepository>().getTodaysExpenses();
  }

  void _refresh() {
    setState(() {
      _expensesFuture = context.read<ShopRepository>().getTodaysExpenses();
    });
  }

  Future<void> _showAddExpenseDialog(BuildContext context) async {
    final repo = context.read<ShopRepository>();
    String category = _kCategories.first;
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _kCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => category = v!),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) return;
                await repo.addExpense(
                  category,
                  amount,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Expenses")),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          final expenses = snapshot.data ?? const <Expense>[];
          final total = expenses.fold(0.0, (a, e) => a + e.amount);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total today', style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : expenses.isEmpty
                        ? const Center(child: Text('No expenses recorded today yet.'))
                        : ListView.separated(
                            itemCount: expenses.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final e = expenses[i];
                              return ListTile(
                                leading: const Icon(Icons.receipt_long, color: Colors.red),
                                title: Text(e.category),
                                subtitle: Text(
                                  DateFormat('h:mm a').format(e.date) +
                                      (e.note != null ? ' • ${e.note}' : ''),
                                ),
                                trailing: Text(
                                  '₹${e.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        onPressed: () => _showAddExpenseDialog(context),
      ),
    );
  }
}

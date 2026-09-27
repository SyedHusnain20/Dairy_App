import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../repository/shop_repository.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Future<List<HistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = context.read<ShopRepository>().getHistory(widget.customerId);
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = context.read<ShopRepository>().getHistory(widget.customerId);
    });
  }

  Future<void> _showAmountDialog(
    BuildContext context, {
    required String title,
    required Future<void> Function(double amount, String? note) onSave,
    bool withNote = false,
  }) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            if (withNote)
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;
              await onSave(
                amount,
                noteController.text.trim().isEmpty ? null : noteController.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _refreshHistory();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Customer? _findCustomer(List<Customer> all) {
    for (final c in all) {
      if (c.id == widget.customerId) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopRepository>(
      builder: (context, repo, _) {
        final customer = _findCustomer(repo.customers);
        if (customer == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final isCredit = customer.currentDue < 0;

        return Scaffold(
          appBar: AppBar(title: Text(customer.name)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isCredit ? 'Credit balance' : 'Total due',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '₹${customer.currentDue.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isCredit ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add Purchase'),
                        onPressed: () => _showAmountDialog(
                          context,
                          title: 'Add Purchase (Khata)',
                          withNote: true,
                          onSave: (amount, note) => context
                              .read<ShopRepository>()
                              .addPurchase(widget.customerId, amount, note: note),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.payments),
                        label: const Text('Add Payment'),
                        onPressed: () => _showAmountDialog(
                          context,
                          title: 'Record Payment',
                          onSave: (amount, _) => context
                              .read<ShopRepository>()
                              .addPayment(widget.customerId, amount),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<HistoryEntry>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final history = snapshot.data ?? const <HistoryEntry>[];
                    if (history.isEmpty) {
                      return const Center(child: Text('No transactions yet.'));
                    }
                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, i) {
                        final entry = history[i];
                        return ListTile(
                          leading: Icon(
                            entry.isPurchase
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: entry.isPurchase ? Colors.red : Colors.green,
                          ),
                          title: Text(entry.isPurchase ? 'Purchase' : 'Payment received'),
                          subtitle: Text(
                            DateFormat('d MMM y, h:mm a').format(entry.date) +
                                (entry.note != null ? ' — ${entry.note}' : ''),
                          ),
                          trailing: Text(
                            '${entry.isPurchase ? '+' : '-'}₹${entry.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: entry.isPurchase ? Colors.red : Colors.green,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

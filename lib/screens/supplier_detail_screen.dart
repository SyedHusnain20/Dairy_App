import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../repository/shop_repository.dart';

class SupplierDetailScreen extends StatefulWidget {
  final int supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  late Future<List<HistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopRepository>().loadProducts();
    });
    _historyFuture =
        context.read<ShopRepository>().getSupplierHistory(widget.supplierId);
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture =
          context.read<ShopRepository>().getSupplierHistory(widget.supplierId);
    });
  }

  Future<void> _showPurchaseDialog(BuildContext context) async {
    final repo = context.read<ShopRepository>();
    Product? selectedProduct;
    final qtyController = TextEditingController(text: '1');
    final rateController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final qty = double.tryParse(qtyController.text.trim()) ?? 0;
          final rate = double.tryParse(rateController.text.trim()) ?? 0;
          final total = qty * rate;

          return AlertDialog(
            title: const Text('Add Purchase'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: repo.products
                        .map((p) => DropdownMenuItem(
                            value: p, child: Text('${p.name} (${p.unit})')))
                        .toList(),
                    onChanged: (product) => setDialogState(() {
                      selectedProduct = product;
                      if (product != null) {
                        rateController.text = product.price.toStringAsFixed(0);
                      }
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          decoration: const InputDecoration(labelText: 'Quantity'),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: rateController,
                          decoration: const InputDecoration(labelText: 'Rate (₹)'),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Total: ₹${total.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (selectedProduct == null || qty <= 0 || rate <= 0) return;
                  await repo.addSupplierPurchase(
                    widget.supplierId,
                    selectedProduct!.id,
                    qty,
                    rate,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _refreshHistory();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    final repo = context.read<ShopRepository>();
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(labelText: 'Amount (₹)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;
              await repo.addSupplierPayment(widget.supplierId, amount);
              if (ctx.mounted) Navigator.pop(ctx);
              _refreshHistory();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Supplier? _findSupplier(List<Supplier> all) {
    for (final s in all) {
      if (s.id == widget.supplierId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopRepository>(
      builder: (context, repo, _) {
        final supplier = _findSupplier(repo.suppliers);
        if (supplier == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final isCredit = supplier.currentDue < 0;

        return Scaffold(
          appBar: AppBar(title: Text(supplier.name)),
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
                          isCredit ? 'Credit (they owe you)' : 'You owe',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '₹${supplier.currentDue.abs().toStringAsFixed(0)}',
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
                        onPressed: () => _showPurchaseDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.payments),
                        label: const Text('Add Payment'),
                        onPressed: () => _showPaymentDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<HistoryEntry>>(
                  future: _historyFuture,
                  builder: (context, historySnap) {
                    if (historySnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final history = historySnap.data ?? const <HistoryEntry>[];
                    if (history.isEmpty) {
                      return const Center(child: Text('No transactions yet.'));
                    }
                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, i) {
                        final entry = history[i];
                        final isDueUp = entry.kind != 'payment';
                        return ListTile(
                          leading: Icon(
                            isDueUp ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isDueUp ? Colors.red : Colors.green,
                          ),
                          title: Text(isDueUp
                              ? 'Purchase${entry.note != null ? ': ${entry.note}' : ''}'
                              : 'Payment sent'),
                          subtitle:
                              Text(DateFormat('d MMM y, h:mm a').format(entry.date)),
                          trailing: Text(
                            '${isDueUp ? '+' : '-'}₹${entry.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDueUp ? Colors.red : Colors.green,
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

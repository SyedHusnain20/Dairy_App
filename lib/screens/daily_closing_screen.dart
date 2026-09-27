import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../repository/shop_repository.dart';

class DailyClosingScreen extends StatefulWidget {
  const DailyClosingScreen({super.key});

  @override
  State<DailyClosingScreen> createState() => _DailyClosingScreenState();
}

class _DailyClosingScreenState extends State<DailyClosingScreen> {
  late Future<ClosingSummary> _summaryFuture;
  final _openingController = TextEditingController();
  final _actualController = TextEditingController();
  bool _fieldsInitialized = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = context.read<ShopRepository>().getTodaysClosingSummary();
  }

  @override
  void dispose() {
    _openingController.dispose();
    _actualController.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Future<void> _save(ClosingSummary summary) async {
    final opening = _num(_openingController);
    final actual = _num(_actualController);

    final difference = await context.read<ShopRepository>().saveDailyClosing(
          openingCash: opening,
          cashSales: summary.cashSales,
          khataPayments: summary.khataPayments,
          supplierPayments: summary.supplierPayments,
          actualCash: actual,
        );

    if (!mounted) return;
    setState(() {
      _summaryFuture = context.read<ShopRepository>().getTodaysClosingSummary();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          difference == 0
              ? 'Closing saved — matched exactly'
              : 'Closing saved — ${difference > 0 ? 'surplus' : 'shortfall'} of ₹${difference.abs().toStringAsFixed(0)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Closing — ${DateFormat('d MMM y').format(DateTime.now())}'),
      ),
      body: FutureBuilder<ClosingSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summary = snapshot.data!;
          final existing = summary.existing;

          if (!_fieldsInitialized) {
            _openingController.text =
                (existing?.openingCash ?? summary.previousCash).toStringAsFixed(0);
            if (existing != null) {
              _actualController.text = existing.actualCash.toStringAsFixed(0);
            }
            _fieldsInitialized = true;
          }

          final opening = _num(_openingController);
          final expected = opening +
              summary.cashSales +
              summary.khataPayments -
              summary.supplierPayments;
          final hasActual = _actualController.text.trim().isNotEmpty;
          final actual = _num(_actualController);
          final difference = hasActual ? actual - expected : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (existing != null)
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "Today's closing is already saved below. Change any field and save again to correct it.",
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'Opening cash',
                editable: true,
                controller: _openingController,
                onChanged: () => setState(() {}),
              ),
              _SummaryRow(label: 'Cash sales today', value: summary.cashSales),
              _SummaryRow(
                  label: 'Khata payments received', value: summary.khataPayments),
              _SummaryRow(
                label: 'Supplier payments made',
                value: summary.supplierPayments,
                isNegative: true,
              ),
              const Divider(height: 32),
              _SummaryRow(label: 'Expected cash', value: expected, bold: true),
              const SizedBox(height: 20),
              TextField(
                controller: _actualController,
                decoration: const InputDecoration(
                  labelText: 'Actual cash counted (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (difference != null)
                Card(
                  color: (difference == 0
                          ? Colors.green
                          : (difference > 0 ? Colors.blue : Colors.red))
                      .withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          difference == 0
                              ? 'Matches exactly ✓'
                              : (difference > 0 ? 'Surplus' : 'Shortfall'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '₹${difference.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: difference == 0
                                ? Colors.green
                                : (difference > 0 ? Colors.blue : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: hasActual ? () => _save(summary) : null,
                child: Text(existing != null ? 'Update Closing' : 'Save Closing'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double? value;
  final bool bold;
  final bool isNegative;
  final bool editable;
  final TextEditingController? controller;
  final VoidCallback? onChanged;

  const _SummaryRow({
    required this.label,
    this.value,
    this.bold = false,
    this.isNegative = false,
    this.editable = false,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 18 : 15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          editable
              ? SizedBox(
                  width: 120,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(prefixText: '₹', isDense: true),
                    onChanged: (_) => onChanged?.call(),
                  ),
                )
              : Text(
                  '${isNegative ? '− ' : ''}₹${value!.toStringAsFixed(0)}',
                  style: style,
                ),
        ],
      ),
    );
  }
}

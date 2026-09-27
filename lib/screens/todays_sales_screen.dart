import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../repository/shop_repository.dart';
import 'add_sale_screen.dart';
import 'products_screen.dart';

class TodaysSalesScreen extends StatefulWidget {
  const TodaysSalesScreen({super.key});

  @override
  State<TodaysSalesScreen> createState() => _TodaysSalesScreenState();
}

class _TodaysSalesScreenState extends State<TodaysSalesScreen> {
  late Future<List<SaleRecord>> _salesFuture;

  @override
  void initState() {
    super.initState();
    _salesFuture = context.read<ShopRepository>().getTodaysSales();
  }

  void _refresh() {
    setState(() {
      _salesFuture = context.read<ShopRepository>().getTodaysSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Sales"),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Edit product prices',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<SaleRecord>>(
        future: _salesFuture,
        builder: (context, snapshot) {
          final sales = snapshot.data ?? const <SaleRecord>[];
          final cashTotal =
              sales.where((s) => s.type == 'cash').fold(0.0, (a, s) => a + s.total);
          final khataTotal =
              sales.where((s) => s.type == 'khata').fold(0.0, (a, s) => a + s.total);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Total(label: 'Cash', value: cashTotal, color: Colors.green),
                        _Total(label: 'Khata', value: khataTotal, color: Colors.orange),
                        _Total(
                            label: 'Total',
                            value: cashTotal + khataTotal,
                            color: Colors.teal),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : sales.isEmpty
                        ? const Center(child: Text('No sales recorded today yet.'))
                        : ListView.builder(
                            itemCount: sales.length,
                            itemBuilder: (context, i) {
                              final s = sales[i];
                              return ListTile(
                                leading: Icon(
                                  s.type == 'cash' ? Icons.money : Icons.book,
                                  color: s.type == 'cash' ? Colors.green : Colors.orange,
                                ),
                                title: Text('${s.productName} — ${s.qty} ${s.unit}'),
                                subtitle: Text(
                                  '${s.type == 'khata' ? 'Khata: ${s.customerName ?? ''}' : 'Cash sale'} • ${DateFormat('h:mm a').format(s.date)}',
                                ),
                                trailing: Text(
                                  '₹${s.total.toStringAsFixed(0)}',
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
        label: const Text('Add Sale'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSaleScreen()),
          );
          _refresh();
        },
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _Total({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
        ),
      ],
    );
  }
}

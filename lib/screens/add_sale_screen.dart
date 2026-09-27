import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/shop_repository.dart';

class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  Product? _selectedProduct;
  Customer? _selectedCustomer;
  String _paymentType = 'cash'; // 'cash' or 'khata'
  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = context.read<ShopRepository>();
      repo.loadProducts();
      repo.loadCustomers();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _onProductChanged(Product? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _rateController.text = product.price.toStringAsFixed(0);
      }
    });
  }

  double get _qty => double.tryParse(_qtyController.text.trim()) ?? 0;
  double get _rate => double.tryParse(_rateController.text.trim()) ?? 0;
  double get _total => _qty * _rate;

  Future<void> _save() async {
    if (_selectedProduct == null || _qty <= 0 || _rate <= 0) return;
    if (_paymentType == 'khata' && _selectedCustomer == null) return;

    final repo = context.read<ShopRepository>();
    final savedTotal = _total;
    await repo.addSale(
      type: _paymentType,
      customerId: _paymentType == 'khata' ? _selectedCustomer!.id : null,
      productId: _selectedProduct!.id,
      qty: _qty,
      rate: _rate,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sale recorded — ₹${savedTotal.toStringAsFixed(0)}')),
    );
    setState(() {
      _selectedProduct = null;
      _selectedCustomer = null;
      _paymentType = 'cash';
      _qtyController.text = '1';
      _rateController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ShopRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Record Sale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              decoration: const InputDecoration(labelText: 'Product'),
              items: repo.products
                  .map((p) => DropdownMenuItem(
                      value: p, child: Text('${p.name} (${p.unit})')))
                  .toList(),
              onChanged: _onProductChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _rateController,
                    decoration: const InputDecoration(labelText: 'Rate (₹)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total: ₹${_total.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'cash', label: Text('Cash'), icon: Icon(Icons.money)),
                ButtonSegment(
                    value: 'khata', label: Text('Khata'), icon: Icon(Icons.book)),
              ],
              selected: {_paymentType},
              onSelectionChanged: (s) => setState(() {
                _paymentType = s.first;
                if (_paymentType == 'cash') _selectedCustomer = null;
              }),
            ),
            if (_paymentType == 'khata') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: repo.customers
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (c) => setState(() => _selectedCustomer = c),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Text('Save Sale'),
            ),
          ],
        ),
      ),
    );
  }
}

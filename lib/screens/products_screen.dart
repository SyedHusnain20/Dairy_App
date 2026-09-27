import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/shop_repository.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopRepository>().loadProducts();
    });
  }

  Future<void> _editPrice(Product product) async {
    final repo = context.read<ShopRepository>();
    final controller = TextEditingController(text: product.price.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${product.name} price'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Price per ${product.unit} (₹)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final price = double.tryParse(controller.text.trim());
              if (price == null || price < 0) return;
              await repo.updateProductPrice(product.id, price);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ShopRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Prices')),
      body: ListView.separated(
        itemCount: repo.products.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final product = repo.products[i];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('per ${product.unit}'),
            trailing: Text(
              '₹${product.price.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () => _editPrice(product),
          );
        },
      ),
    );
  }
}

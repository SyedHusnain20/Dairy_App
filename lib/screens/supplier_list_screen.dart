import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/shop_repository.dart';
import 'supplier_detail_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopRepository>().loadSuppliers();
    });
  }

  Future<void> _showAddSupplierDialog(BuildContext context) async {
    final repo = context.read<ShopRepository>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final dueController = TextEditingController(text: '0');
    String? category;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Supplier'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Category (optional)'),
                items: const [
                  DropdownMenuItem(value: 'Milk', child: Text('Milk')),
                  DropdownMenuItem(value: 'Rusk', child: Text('Rusk')),
                  DropdownMenuItem(value: 'Bread', child: Text('Bread')),
                  DropdownMenuItem(value: 'Butter', child: Text('Butter')),
                  DropdownMenuItem(value: 'Eggs', child: Text('Eggs')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setDialogState(() => category = v),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Contact (optional)'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: dueController,
                decoration: const InputDecoration(labelText: 'Previous / opening due'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final due = double.tryParse(dueController.text.trim()) ?? 0;
                await repo.addSupplier(
                  name,
                  category: category,
                  contact: contactController.text.trim().isEmpty
                      ? null
                      : contactController.text.trim(),
                  openingDue: due,
                );
                if (ctx.mounted) Navigator.pop(ctx);
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
      appBar: AppBar(title: const Text('Suppliers')),
      body: Consumer<ShopRepository>(
        builder: (context, repo, _) {
          if (repo.suppliers.isEmpty) {
            return const Center(
              child: Text('No suppliers yet. Tap + to add one.'),
            );
          }
          return ListView.separated(
            itemCount: repo.suppliers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final supplier = repo.suppliers[i];
              final isCredit = supplier.currentDue < 0;
              final subtitleParts = [
                if (supplier.category != null) supplier.category!,
                if (supplier.contact != null) supplier.contact!,
              ];
              return ListTile(
                title: Text(supplier.name),
                subtitle:
                    subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
                trailing: Text(
                  isCredit
                      ? 'Credit ₹${(-supplier.currentDue).toStringAsFixed(0)}'
                      : '₹${supplier.currentDue.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCredit
                        ? Colors.green
                        : (supplier.currentDue > 0 ? Colors.red : Colors.grey),
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupplierDetailScreen(supplierId: supplier.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierDialog(context),
        tooltip: 'Add supplier',
        child: const Icon(Icons.local_shipping),
      ),
    );
  }
}

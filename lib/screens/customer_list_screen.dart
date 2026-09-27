import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/shop_repository.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopRepository>().loadCustomers();
    });
  }

  Future<void> _showAddCustomerDialog(BuildContext context) async {
    final repo = context.read<ShopRepository>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final dueController = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final due = double.tryParse(dueController.text.trim()) ?? 0;
              await repo.addCustomer(
                name,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Consumer<ShopRepository>(
        builder: (context, repo, _) {
          if (repo.customers.isEmpty) {
            return const Center(
              child: Text('No customers yet. Tap + to add one.'),
            );
          }
          return ListView.separated(
            itemCount: repo.customers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final customer = repo.customers[i];
              final isCredit = customer.currentDue < 0;
              return ListTile(
                title: Text(customer.name),
                subtitle:
                    customer.contact != null ? Text(customer.contact!) : null,
                trailing: Text(
                  isCredit
                      ? 'Credit ₹${(-customer.currentDue).toStringAsFixed(0)}'
                      : '₹${customer.currentDue.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCredit
                        ? Colors.green
                        : (customer.currentDue > 0 ? Colors.red : Colors.grey),
                  ),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailScreen(customerId: customer.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context),
        tooltip: 'Add customer',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

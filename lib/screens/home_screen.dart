import 'package:flutter/material.dart';
import 'customer_list_screen.dart';
import 'daily_closing_screen.dart';
import 'expenses_screen.dart';
import 'supplier_list_screen.dart';
import 'todays_sales_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dairy Shop')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _HomeTile(
            icon: Icons.people,
            label: 'Customers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerListScreen()),
            ),
          ),
          _HomeTile(
            icon: Icons.point_of_sale,
            label: 'Sales',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TodaysSalesScreen()),
            ),
          ),
          _HomeTile(
            icon: Icons.local_shipping,
            label: 'Suppliers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupplierListScreen()),
            ),
          ),
          _HomeTile(
            icon: Icons.calculate,
            label: 'Daily Closing',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailyClosingScreen()),
            ),
          ),
          _HomeTile(
            icon: Icons.receipt_long,
            label: 'Expenses',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpensesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

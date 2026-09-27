import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';

class Customer {
  final int id;
  final String name;
  final String? contact;
  final double openingDue;
  final double currentDue;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.contact,
    required this.openingDue,
    required this.currentDue,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as int,
        name: m['name'] as String,
        contact: m['contact'] as String?,
        openingDue: (m['openingDue'] as num).toDouble(),
        currentDue: (m['currentDue'] as num).toDouble(),
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

class HistoryEntry {
  final DateTime date;
  final double amount;
  final bool isPurchase; // true = khata purchase (due up), false = payment (due down)
  final String? note;

  HistoryEntry({
    required this.date,
    required this.amount,
    required this.isPurchase,
    this.note,
  });
}

/// Holds the customer list in memory and notifies the UI after every write.
/// Detail-screen history is fetched on demand (see getHistory) rather than
/// cached here, since it's only needed on one screen at a time.
class ShopRepository extends ChangeNotifier {
  List<Customer> customers = [];

  Future<void> loadCustomers() async {
    final db = await DbHelper.instance.database;
    final rows = await db.query('customers', orderBy: 'name COLLATE NOCASE');
    customers = rows.map(Customer.fromMap).toList();
    notifyListeners();
  }

  Future<void> addCustomer(String name,
      {String? contact, double openingDue = 0}) async {
    final db = await DbHelper.instance.database;
    await db.insert('customers', {
      'name': name,
      'contact': contact,
      'openingDue': openingDue,
      'currentDue': openingDue,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await loadCustomers();
  }

  Future<void> addPurchase(int customerId, double amount, {String? note}) async {
    final db = await DbHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert('purchases', {
        'customerId': customerId,
        'amount': amount,
        'note': note,
        'date': DateTime.now().toIso8601String(),
      });
      await txn.rawUpdate(
        'UPDATE customers SET currentDue = currentDue + ? WHERE id = ?',
        [amount, customerId],
      );
    });
    await loadCustomers();
  }

  Future<void> addPayment(int customerId, double amount) async {
    final db = await DbHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert('payments', {
        'customerId': customerId,
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
      });
      await txn.rawUpdate(
        'UPDATE customers SET currentDue = currentDue - ? WHERE id = ?',
        [amount, customerId],
      );
    });
    await loadCustomers();
  }

  Future<List<HistoryEntry>> getHistory(int customerId) async {
    final db = await DbHelper.instance.database;
    final purchaseRows = await db
        .query('purchases', where: 'customerId = ?', whereArgs: [customerId]);
    final paymentRows = await db
        .query('payments', where: 'customerId = ?', whereArgs: [customerId]);

    final entries = <HistoryEntry>[
      ...purchaseRows.map((r) => HistoryEntry(
            date: DateTime.parse(r['date'] as String),
            amount: (r['amount'] as num).toDouble(),
            isPurchase: true,
            note: r['note'] as String?,
          )),
      ...paymentRows.map((r) => HistoryEntry(
            date: DateTime.parse(r['date'] as String),
            amount: (r['amount'] as num).toDouble(),
            isPurchase: false,
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return entries;
  }
}

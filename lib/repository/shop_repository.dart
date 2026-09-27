import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
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

class Supplier {
  final int id;
  final String name;
  final String? category;
  final String? contact;
  final double openingDue;
  final double currentDue;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.category,
    this.contact,
    required this.openingDue,
    required this.currentDue,
    required this.createdAt,
  });

  factory Supplier.fromMap(Map<String, Object?> m) => Supplier(
        id: m['id'] as int,
        name: m['name'] as String,
        category: m['category'] as String?,
        contact: m['contact'] as String?,
        openingDue: (m['openingDue'] as num).toDouble(),
        currentDue: (m['currentDue'] as num).toDouble(),
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}

class Product {
  final int id;
  final String name;
  final String unit;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
  });

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as int,
        name: m['name'] as String,
        unit: m['unit'] as String,
        price: (m['price'] as num).toDouble(),
      );
}

/// A sale as shown on the Today's Sales screen — includes the joined
/// product name/unit and (for khata sales) the customer name.
class SaleRecord {
  final int id;
  final String type; // 'cash' or 'khata'
  final int? customerId;
  final String? customerName;
  final int productId;
  final String productName;
  final String unit;
  final double qty;
  final double rate;
  final double total;
  final DateTime date;

  SaleRecord({
    required this.id,
    required this.type,
    this.customerId,
    this.customerName,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.qty,
    required this.rate,
    required this.total,
    required this.date,
  });
}

/// One line in a customer's history — a manual khata purchase, a khata
/// product sale, or a payment received. 'purchase' and 'sale' both
/// increase currentDue; 'payment' decreases it.
class HistoryEntry {
  final DateTime date;
  final double amount;
  final String kind; // 'purchase' | 'payment' | 'sale'
  final String? note;

  HistoryEntry({
    required this.date,
    required this.amount,
    required this.kind,
    this.note,
  });
}

class DailyClosing {
  final int id;
  final String date;
  final double openingCash;
  final double cashSales;
  final double khataPayments;
  final double supplierPayments;
  final double expectedCash;
  final double actualCash;
  final double difference;
  final DateTime closedAt;

  DailyClosing({
    required this.id,
    required this.date,
    required this.openingCash,
    required this.cashSales,
    required this.khataPayments,
    required this.supplierPayments,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    required this.closedAt,
  });

  factory DailyClosing.fromMap(Map<String, Object?> m) => DailyClosing(
        id: m['id'] as int,
        date: m['date'] as String,
        openingCash: (m['openingCash'] as num).toDouble(),
        cashSales: (m['cashSales'] as num).toDouble(),
        khataPayments: (m['khataPayments'] as num).toDouble(),
        supplierPayments: (m['supplierPayments'] as num).toDouble(),
        expectedCash: (m['expectedCash'] as num).toDouble(),
        actualCash: (m['actualCash'] as num).toDouble(),
        difference: (m['difference'] as num).toDouble(),
        closedAt: DateTime.parse(m['closedAt'] as String),
      );
}

/// Everything the Daily Closing screen needs: today's computed totals,
/// the previous day's counted cash (as a default opening cash), and
/// today's closing record if one was already saved.
class ClosingSummary {
  final double previousCash;
  final double cashSales;
  final double khataPayments;
  final double supplierPayments;
  final DailyClosing? existing;

  ClosingSummary({
    required this.previousCash,
    required this.cashSales,
    required this.khataPayments,
    required this.supplierPayments,
    this.existing,
  });
}

class ShopRepository extends ChangeNotifier {
  List<Customer> customers = [];
  List<Product> products = [];
  List<Supplier> suppliers = [];

  // ---------- Customers ----------

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

  // ---------- Purchases (manual khata due entries) ----------

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

  // ---------- Payments ----------

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

  // ---------- Products ----------

  Future<void> loadProducts() async {
    final db = await DbHelper.instance.database;
    final rows = await db.query('products', orderBy: 'name COLLATE NOCASE');
    products = rows.map(Product.fromMap).toList();
    notifyListeners();
  }

  Future<void> updateProductPrice(int productId, double price) async {
    final db = await DbHelper.instance.database;
    await db.update('products', {'price': price},
        where: 'id = ?', whereArgs: [productId]);
    await loadProducts();
  }

  // ---------- Suppliers ----------

  Future<void> loadSuppliers() async {
    final db = await DbHelper.instance.database;
    final rows = await db.query('suppliers', orderBy: 'name COLLATE NOCASE');
    suppliers = rows.map(Supplier.fromMap).toList();
    notifyListeners();
  }

  Future<void> addSupplier(String name,
      {String? category, String? contact, double openingDue = 0}) async {
    final db = await DbHelper.instance.database;
    await db.insert('suppliers', {
      'name': name,
      'category': category,
      'contact': contact,
      'openingDue': openingDue,
      'currentDue': openingDue,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await loadSuppliers();
  }

  /// Records goods received from a supplier — increases what you owe them.
  Future<void> addSupplierPurchase(
    int supplierId,
    int productId,
    double qty,
    double rate, {
    String? note,
  }) async {
    final db = await DbHelper.instance.database;
    final amount = qty * rate;
    await db.transaction((txn) async {
      await txn.insert('supplier_purchases', {
        'supplierId': supplierId,
        'productId': productId,
        'qty': qty,
        'rate': rate,
        'amount': amount,
        'note': note,
        'date': DateTime.now().toIso8601String(),
      });
      await txn.rawUpdate(
        'UPDATE suppliers SET currentDue = currentDue + ? WHERE id = ?',
        [amount, supplierId],
      );
    });
    await loadSuppliers();
  }

  /// Records money you paid a supplier — decreases what you owe them.
  Future<void> addSupplierPayment(int supplierId, double amount) async {
    final db = await DbHelper.instance.database;
    await db.transaction((txn) async {
      await txn.insert('supplier_payments', {
        'supplierId': supplierId,
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
      });
      await txn.rawUpdate(
        'UPDATE suppliers SET currentDue = currentDue - ? WHERE id = ?',
        [amount, supplierId],
      );
    });
    await loadSuppliers();
  }

  Future<List<HistoryEntry>> getSupplierHistory(int supplierId) async {
    final db = await DbHelper.instance.database;
    final purchaseRows = await db.rawQuery('''
      SELECT supplier_purchases.*, products.name as productName, products.unit as unit
      FROM supplier_purchases
      LEFT JOIN products ON products.id = supplier_purchases.productId
      WHERE supplier_purchases.supplierId = ?
    ''', [supplierId]);
    final paymentRows = await db.query('supplier_payments',
        where: 'supplierId = ?', whereArgs: [supplierId]);

    final entries = <HistoryEntry>[
      ...purchaseRows.map((r) {
        final productLabel =
            '${r['qty'] ?? ''} ${r['unit'] ?? ''} ${r['productName'] ?? ''}'.trim();
        final note = r['note'] as String?;
        return HistoryEntry(
          date: DateTime.parse(r['date'] as String),
          amount: (r['amount'] as num).toDouble(),
          kind: 'purchase',
          note: note != null ? '$productLabel — $note' : productLabel,
        );
      }),
      ...paymentRows.map((r) => HistoryEntry(
            date: DateTime.parse(r['date'] as String),
            amount: (r['amount'] as num).toDouble(),
            kind: 'payment',
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return entries;
  }

  // ---------- Sales ----------

  /// Records a sale. Cash sales don't touch any customer's due. Khata
  /// sales add the sale total to that customer's currentDue, the same
  /// way addPurchase does.
  Future<void> addSale({
    required String type, // 'cash' or 'khata'
    int? customerId,
    required int productId,
    required double qty,
    required double rate,
  }) async {
    final db = await DbHelper.instance.database;
    final total = qty * rate;
    await db.transaction((txn) async {
      await txn.insert('sales', {
        'type': type,
        'customerId': customerId,
        'productId': productId,
        'qty': qty,
        'rate': rate,
        'total': total,
        'date': DateTime.now().toIso8601String(),
      });
      if (type == 'khata' && customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET currentDue = currentDue + ? WHERE id = ?',
          [total, customerId],
        );
      }
    });
    if (type == 'khata') await loadCustomers();
  }

  Future<List<SaleRecord>> getTodaysSales() async {
    final db = await DbHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT sales.*, products.name as productName, products.unit as unit,
             customers.name as customerName
      FROM sales
      LEFT JOIN products ON products.id = sales.productId
      LEFT JOIN customers ON customers.id = sales.customerId
      WHERE date(sales.date) = date('now', 'localtime')
      ORDER BY sales.date DESC
    ''');
    return rows
        .map((r) => SaleRecord(
              id: r['id'] as int,
              type: r['type'] as String,
              customerId: r['customerId'] as int?,
              customerName: r['customerName'] as String?,
              productId: r['productId'] as int,
              productName: r['productName'] as String? ?? 'Unknown',
              unit: r['unit'] as String? ?? '',
              qty: (r['qty'] as num).toDouble(),
              rate: (r['rate'] as num).toDouble(),
              total: (r['total'] as num).toDouble(),
              date: DateTime.parse(r['date'] as String),
            ))
        .toList();
  }

  // ---------- Combined customer history ----------

  Future<List<HistoryEntry>> getHistory(int customerId) async {
    final db = await DbHelper.instance.database;
    final purchaseRows = await db
        .query('purchases', where: 'customerId = ?', whereArgs: [customerId]);
    final paymentRows = await db
        .query('payments', where: 'customerId = ?', whereArgs: [customerId]);
    final saleRows = await db.rawQuery('''
      SELECT sales.*, products.name as productName, products.unit as unit
      FROM sales
      LEFT JOIN products ON products.id = sales.productId
      WHERE sales.customerId = ? AND sales.type = 'khata'
    ''', [customerId]);

    final entries = <HistoryEntry>[
      ...purchaseRows.map((r) => HistoryEntry(
            date: DateTime.parse(r['date'] as String),
            amount: (r['amount'] as num).toDouble(),
            kind: 'purchase',
            note: r['note'] as String?,
          )),
      ...paymentRows.map((r) => HistoryEntry(
            date: DateTime.parse(r['date'] as String),
            amount: (r['amount'] as num).toDouble(),
            kind: 'payment',
          )),
      ...saleRows.map((r) => HistoryEntry(
            date: DateTime.parse(r['date'] as String),
            amount: (r['total'] as num).toDouble(),
            kind: 'sale',
            note: '${r['qty']} ${r['unit'] ?? ''} ${r['productName'] ?? ''}'.trim(),
          )),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return entries;
  }

  // ---------- Daily Closing ----------

  String _todayKey() => DateTime.now().toIso8601String().substring(0, 10);

  Future<ClosingSummary> getTodaysClosingSummary() async {
    final db = await DbHelper.instance.database;
    final todayKey = _todayKey();

    final existingRows =
        await db.query('daily_closings', where: 'date = ?', whereArgs: [todayKey]);
    final existing =
        existingRows.isNotEmpty ? DailyClosing.fromMap(existingRows.first) : null;

    final prevRows = await db.query(
      'daily_closings',
      where: 'date < ?',
      whereArgs: [todayKey],
      orderBy: 'date DESC',
      limit: 1,
    );
    final previousCash =
        prevRows.isNotEmpty ? (prevRows.first['actualCash'] as num).toDouble() : 0.0;

    final cashSalesResult = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total FROM sales
      WHERE type = 'cash' AND date(date) = date('now', 'localtime')
    ''');
    final cashSales = (cashSalesResult.first['total'] as num).toDouble();

    final khataPaymentsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM payments
      WHERE date(date) = date('now', 'localtime')
    ''');
    final khataPayments = (khataPaymentsResult.first['total'] as num).toDouble();

    final supplierPaymentsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total FROM supplier_payments
      WHERE date(date) = date('now', 'localtime')
    ''');
    final supplierPayments =
        (supplierPaymentsResult.first['total'] as num).toDouble();

    return ClosingSummary(
      previousCash: previousCash,
      cashSales: cashSales,
      khataPayments: khataPayments,
      supplierPayments: supplierPayments,
      existing: existing,
    );
  }

  /// Saves (or overwrites, if already saved today) the daily closing.
  /// Expected cash = opening + cash sales + khata payments in - supplier
  /// payments out. Expenses aren't tracked yet, so they're not part of
  /// this formula — once built, they'll subtract here too.
  Future<double> saveDailyClosing({
    required double openingCash,
    required double cashSales,
    required double khataPayments,
    required double supplierPayments,
    required double actualCash,
  }) async {
    final db = await DbHelper.instance.database;
    final expectedCash = openingCash + cashSales + khataPayments - supplierPayments;
    final difference = actualCash - expectedCash;
    await db.insert(
      'daily_closings',
      {
        'date': _todayKey(),
        'openingCash': openingCash,
        'cashSales': cashSales,
        'khataPayments': khataPayments,
        'supplierPayments': supplierPayments,
        'expectedCash': expectedCash,
        'actualCash': actualCash,
        'difference': difference,
        'closedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return difference;
  }
}

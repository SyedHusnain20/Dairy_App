import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens (and creates, on first run) the local SQLite file.
/// Uses sqflite's own getDatabasesPath() instead of path_provider, since
/// path_provider's Android implementation now requires a native JNI build
/// (NDK/CMake) that this project doesn't otherwise need.
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, 'dairy_shop.db');
    return openDatabase(
      path,
      version: 4,
      onCreate: _createAll,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createSupplierTables(db);
        }
        if (oldVersion < 3) {
          await _createDailyClosingTable(db);
        }
        if (oldVersion < 4) {
          await _createExpensesTable(db);
          await db.execute(
            'ALTER TABLE daily_closings ADD COLUMN expenses REAL NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  Future<void> _createAll(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT,
        openingDue REAL NOT NULL DEFAULT 0,
        currentDue REAL NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE purchases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY(customerId) REFERENCES customers(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY(customerId) REFERENCES customers(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        customerId INTEGER,
        productId INTEGER NOT NULL,
        qty REAL NOT NULL,
        rate REAL NOT NULL,
        total REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY(customerId) REFERENCES customers(id),
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');

    // Seed the shop's product list. Prices start at 0 — set them from
    // the Products screen (the tune icon on the Sales screen).
    final defaultProducts = [
      {'name': 'Milk', 'unit': 'liter'},
      {'name': 'Yogurt', 'unit': 'kg'},
      {'name': 'Rusk', 'unit': 'piece'},
      {'name': 'Bread', 'unit': 'piece'},
      {'name': 'Butter', 'unit': 'kg'},
      {'name': 'Eggs', 'unit': 'dozen'},
    ];
    for (final product in defaultProducts) {
      await db.insert('products', {
        'name': product['name'],
        'unit': product['unit'],
        'price': 0.0,
      });
    }

    await _createSupplierTables(db);
    await _createDailyClosingTable(db);
    await _createExpensesTable(db);
  }

  Future<void> _createSupplierTables(Database db) async {
    await db.execute('''
      CREATE TABLE suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        contact TEXT,
        openingDue REAL NOT NULL DEFAULT 0,
        currentDue REAL NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE supplier_purchases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        productId INTEGER,
        qty REAL,
        rate REAL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY(supplierId) REFERENCES suppliers(id),
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE supplier_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplierId INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY(supplierId) REFERENCES suppliers(id)
      )
    ''');
  }

  Future<void> _createDailyClosingTable(Database db) async {
    await db.execute('''
      CREATE TABLE daily_closings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        openingCash REAL NOT NULL,
        cashSales REAL NOT NULL,
        khataPayments REAL NOT NULL,
        supplierPayments REAL NOT NULL,
        expenses REAL NOT NULL DEFAULT 0,
        expectedCash REAL NOT NULL,
        actualCash REAL NOT NULL,
        difference REAL NOT NULL,
        closedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL
      )
    ''');
  }
}

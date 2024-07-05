import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'budget_tracker.db');
    return await openDatabase(
      path,
      version: 3, // Increment the version number
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY,
            type TEXT,
            date TEXT,
            name TEXT,
            amount REAL,
            category TEXT,
            description TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE transactions ADD COLUMN category TEXT');
        }
        if (oldVersion < 3) {
          await db
              .execute('ALTER TABLE transactions ADD COLUMN description TEXT');
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<void> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    await db.insert('transactions', transaction);
  }

  Future<void> updateTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [transaction['id']],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHandler {
  static final DatabaseHandler _instance = DatabaseHandler._internal();
  static Database? _database;

  DatabaseHandler._internal();

  factory DatabaseHandler() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pathfinder.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE Items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            imageUrl TEXT,
            price REAL,
            barcode TEXT UNIQUE,
            location TEXT,
            x REAL,
            y REAL
          )
        ''');
        await _insertSampleItems(db);
      },
    );
  }

  Future<void> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('Items', item,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return await db.query('Items');
  }

  Future<List<Map<String, dynamic>>> getItemLocations() async {
    final db = await database;
    return await db.query('Items', columns: ['name', 'x', 'y']);
  }

  Future<Map<String, dynamic>?> getItemByBarcode(String barcode) async {
    final db = await database;
    final result =
        await db.query('Items', where: 'barcode = ?', whereArgs: [barcode]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> _insertSampleItems(Database db) async {
    final sampleData = [
      {
        'name': 'Sardines',
        'imageUrl': 'assets/images/sardines.png',
        'price': 20.50,
        'barcode': '123456789012',
        'location': 'Aisle 1',
        'x': 50.0,
        'y': 150.0
      },
      {
        'name': 'Milk',
        'imageUrl': 'assets/images/milk.png',
        'price': 60.00,
        'barcode': '987654321098',
        'location': 'Aisle 3',
        'x': 120.0,
        'y': 200.0
      }
    ];

    for (var item in sampleData) {
      await db.insert('Items', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}

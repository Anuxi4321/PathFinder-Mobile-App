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
    final path = join(dbPath, 'shopping_list.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
            CREATE TABLE Items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              imageUrl TEXT,
              price REAL
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

  Future<void> _insertSampleItems(Database db) async {
    final sampleData = [
      {'name': 'Milk', 'imageUrl': 'assets/images/milk.png', 'price': 60.00},
      {'name': 'Bread', 'imageUrl': 'assets/images/bread.png', 'price': 30.00},
      {'name': 'Eggs', 'imageUrl': 'assets/images/eggs.png', 'price': 50.00},
      {
        'name': 'Butter',
        'imageUrl': 'assets/images/butter.png',
        'price': 90.00
      },
      {
        'name': 'Cheese',
        'imageUrl': 'assets/images/cheese.png',
        'price': 120.00
      },
      {
        'name': 'Apples',
        'imageUrl': 'assets/images/apples.png',
        'price': 80.00
      },
      {
        'name': 'Bananas',
        'imageUrl': 'assets/images/bananas.png',
        'price': 40.00
      },
      {'name': 'Rice', 'imageUrl': 'assets/images/rice.png', 'price': 70.00},
      {
        'name': 'Chicken',
        'imageUrl': 'assets/images/chicken.png',
        'price': 150.00
      },
      {'name': 'Fish', 'imageUrl': 'assets/images/fish.png', 'price': 200.00},
      {'name': 'Pasta', 'imageUrl': 'assets/images/pasta.png', 'price': 60.00},
      {
        'name': 'Tomatoes',
        'imageUrl': 'assets/images/tomatoes.png',
        'price': 45.00
      }
    ];

    for (var item in sampleData) {
      await db.insert('Items', item,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}

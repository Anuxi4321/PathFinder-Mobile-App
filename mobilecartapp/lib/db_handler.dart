import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
    if (Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbDir = await getApplicationDocumentsDirectory();
    final path = join(dbDir.path, 'shopping_list.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4, // Increment version to apply changes
        onCreate: (db, version) async {
          await _createTables(db);
          await _insertSampleItems(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 4) {
            await _createShoppingListsTable(db);
          }
        },
      ),
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        imageUrl TEXT,
        price REAL
      )
    ''');

    await _createShoppingListsTable(db);
  }

  Future<void> _createShoppingListsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ShoppingLists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        quantity INTEGER,
        date TEXT,
        imageUrl TEXT
      )
    ''');
  }

  Future<void> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('Items', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return await db.query('Items');
  }

  Future<void> saveShoppingList(List<Map<String, dynamic>> items) async {
    final db = await database;
    final date = DateTime.now().toIso8601String();

    for (var item in items) {
      await db.insert(
        'ShoppingLists',
        {
          'name': item['name'],
          'quantity': item['quantity'],
          'date': date,
          'imageUrl': item['imageUrl'] ?? '', // Ensure image URL is saved
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getShoppingList() async {
    final db = await database;
    return await db.query('ShoppingLists');
  }

  Future<void> _insertSampleItems(Database db) async {
    final sampleData = [
      {'name': 'Skyflakes', 'imageUrl': 'assets/images/skyflakes.png', 'price': 8.00},
      {'name': 'Fita', 'imageUrl': 'assets/images/fita.png', 'price': 7.00},
      {'name': 'Presto', 'imageUrl': 'assets/images/presto.png', 'price': 7.00},
      {'name': 'Clear', 'imageUrl': 'assets/images/clear.png', 'price': 8.00},
      {'name': 'Sunsilk', 'imageUrl': 'assets/images/sunsilk.png', 'price': 8.00},
      {'name': 'Dove', 'imageUrl': 'assets/images/dove.png', 'price': 9.00},
      {'name': 'Patata', 'imageUrl': 'assets/images/patata.png', 'price': 8.00},
      {'name': 'Oishi', 'imageUrl': 'assets/images/oishi.png', 'price': 8.00},
      {'name': 'Chippy', 'imageUrl': 'assets/images/chippy.png', 'price': 8.00},
      {'name': 'Ariel', 'imageUrl': 'assets/images/ariel.png', 'price': 16.00},
      {'name': 'Surf', 'imageUrl': 'assets/images/surf.png', 'price': 8.00},
      {'name': 'Wings', 'imageUrl': 'assets/images/wings.png', 'price': 8.00},
      {'name': 'Coke', 'imageUrl': 'assets/images/coke.png', 'price': 40.00},
      {'name': 'Sprite', 'imageUrl': 'assets/images/sprite.png', 'price': 40.00},
      {'name': 'Royal', 'imageUrl': 'assets/images/royal.png', 'price': 40.00},
      {'name': 'Cornbeef', 'imageUrl': 'assets/images/cornbeef.png', 'price': 25.00},
      {'name': 'Beefloaf', 'imageUrl': 'assets/images/beefloaf.png', 'price': 30.00},
      {'name': 'Sardines', 'imageUrl': 'assets/images/sardines.png', 'price': 27.00},
    ];

    for (var item in sampleData) {
      await db.insert('Items', item, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> deleteDatabaseFile() async {
    final dbDir = await getApplicationDocumentsDirectory();
    final path = join(dbDir.path, 'shopping_list.db');
    await deleteDatabase(path);
  }
}

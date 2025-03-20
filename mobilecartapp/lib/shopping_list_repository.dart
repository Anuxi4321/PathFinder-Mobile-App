import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'db_handler.dart';

class ShoppingListRepository {
  final DatabaseHandler _dbHandler = DatabaseHandler();

  Future<List<Map<String, dynamic>>> searchItems(String query) async {
    if (query.isEmpty) return [];

    final Database db = await _dbHandler.database;
    return await db.query(
      'Items',
      where: 'LOWER(name) LIKE LOWER(?)',
      whereArgs: ['%$query%'.toLowerCase()],
    );
  }

  Future<void> saveShoppingList(List<Map<String, dynamic>> items) async {
    final Database db = await _dbHandler.database;
    final String timestamp = DateTime.now().toIso8601String();

    await db.insert(
      'ShoppingLists',
      {
        'name': 'Shopping List',
        'date': timestamp,
        'items': jsonEncode(items), // Encode the items as JSON string
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateShoppingList(int listId, List<Map<String, dynamic>> items) async {
    final db = await _dbHandler.database; // Fixing the undefined 'database' error
    await db.update(
      'ShoppingLists',
      {
        'items': jsonEncode(items), // Encode items to JSON
      },
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  Future<List<Map<String, dynamic>>> getShoppingLists() async {
    final Database db = await _dbHandler.database;
    final List<Map<String, dynamic>> result = await db.query('ShoppingLists', orderBy: 'date DESC');
    
    // Decode the items field from JSON
    return result.map((list) {
      final decodedItems = jsonDecode(list['items'] ?? '[]');
      return {
        ...list,
        'items': decodedItems,
      };
    }).toList();
  }
}

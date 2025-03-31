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

    // Check if a shopping list with the same name exists
    final existingList = await db.query(
      'ShoppingLists',
      where: 'name = ?',
      whereArgs: ['Shopping List'],
    );

    if (existingList.isNotEmpty) {
      // Update the existing list
      await db.update(
        'ShoppingLists',
        {
          'date': timestamp,
          'items': jsonEncode(items),
        },
        where: 'name = ?',
        whereArgs: ['Shopping List'],
      );
    } else {
      // Insert a new list
      await db.insert(
        'ShoppingLists',
        {
          'name': 'Shopping List',
          'date': timestamp,
          'items': jsonEncode(items),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }


  Future<void> updateShoppingList(int listId, List<Map<String, dynamic>> items) async {
  final db = await _dbHandler.database;

  final existingList = await db.query(
    'ShoppingLists',
    where: 'id = ?',
    whereArgs: [listId],
  );

  if (existingList.isNotEmpty) {
    await db.update(
      'ShoppingLists',
      {
        'items': jsonEncode(items),
      },
      where: 'id = ?',
      whereArgs: [listId],
    );
  } else {
    print("⚠️ List with id $listId not found.");
  }
}


  Future<List<Map<String, dynamic>>> getShoppingLists() async {
  final Database db = await _dbHandler.database;
  final List<Map<String, dynamic>> result = await db.query('ShoppingLists', orderBy: 'date DESC');

  return result.map((list) {
    try {
      final decodedItems = list['items'] != null ? jsonDecode(list['items']) : [];
      return {
        ...list,
        'items': List<Map<String, dynamic>>.from(decodedItems),
      };
    } catch (e) {
      print("❗ Error decoding items for list ${list['name']}: $e");
      return {
        ...list,
        'items': [],
      };
    }
  }).toList();
}
}

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'db_handler.dart';

class ShoppingListRepository {
  final DatabaseHandler _dbHandler = DatabaseHandler();

  Future<List<Map<String, dynamic>>> searchItems(String query) async {
    if (query.isEmpty) return [];

    final Database db = await _dbHandler.database;

    final result = await db.query(
      'Items',
      columns: ['id', 'name', 'imageUrl', 'price', 'aisle'],
      where: 'LOWER(name) LIKE LOWER(?)',
      whereArgs: ['%$query%'],
    );

    // Debug: Print to confirm 'aisle' is retrieved
    print('🔍 searchItems() result: $result');

    return result;
  }

  Future<void> saveShoppingList(List<Map<String, dynamic>> items, {required String name}) async {
    final Database db = await _dbHandler.database;
    final String timestamp = DateTime.now().toIso8601String();

    await db.insert(
      'ShoppingLists',
      {
        'name': name,
        'date': timestamp,
        'items': jsonEncode(items),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Keep only 10 latest
    final List<Map<String, dynamic>> allLists = await db.query(
      'ShoppingLists',
      orderBy: 'date DESC',
    );

    if (allLists.length > 10) {
      final excessLists = allLists.sublist(10);

      print('⚠️ Deleting ${excessLists.length} old list(s)');

      for (var list in excessLists) {
        await db.delete(
          'ShoppingLists',
          where: 'id = ?',
          whereArgs: [list['id']],
        );
      }
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

  // 🔍 Optional: Debug method to check Items table schema
  Future<void> printItemsTableSchema() async {
    final db = await _dbHandler.database;
    final schema = await db.rawQuery('PRAGMA table_info(Items)');
    print('📋 Items table schema: $schema');
  }
}

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
}

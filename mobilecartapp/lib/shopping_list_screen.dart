import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'db_handler.dart';
import 'package:sqflite/sqflite.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<Map<String, dynamic>> _items = [];
  final TextEditingController _itemController = TextEditingController();
  final DatabaseHandler _dbHandler = DatabaseHandler();
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchItems(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final Database db = await _dbHandler.database;
    final List<Map<String, dynamic>> results = await db.query(
      'Items',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );

    setState(() {
      _searchResults = results;
    });
  }

  void _showAddItemModal(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${item['name']}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(item['imageUrl'], height: 100),
            const SizedBox(height: 10),
            Text('Price: \$${item['price']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.add({'name': item['name'], 'quantity': 1});
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      _items[index]['quantity'] += change;
      if (_items[index]['quantity'] < 1) {
        _items.removeAt(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _syncShoppingList() async {
    try {
      final result = await Navigator.pushNamed(context, '/qr_scanner');
      if (result != null && result is Map<String, dynamic>) {
        final String macAddress = result['mac'];
        final String sessionKey = result['key'];

        final String shoppingListData = jsonEncode({
          'mac': macAddress,
          'key': sessionKey,
          'items': _items,
        });

        final response = await http.post(
          Uri.parse('http://<SMART_CART_IP>:5000/sync_shopping_list'),
          headers: {'Content-Type': 'application/json'},
          body: shoppingListData,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shopping list synced successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to sync shopping list');
        }
      } else {
        throw Exception('Invalid QR code data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sync shopping list. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping List',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 10,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Search Box
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    TextField(
                      controller: _itemController,
                      onChanged: _searchItems,
                      decoration: InputDecoration(
                        hintText: 'Search for items',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),
                    // Dropdown for search results
                    if (_searchResults.isNotEmpty)
                      Container(
                        color: Colors.white,
                        child: Column(
                          children: _searchResults.map((item) {
                            return ListTile(
                              title: Text(item['name']),
                              onTap: () => _showAddItemModal(item),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Shopping List
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 20),
                                  onPressed: () => _updateQuantity(index, -1),
                                  color: Colors.red,
                                ),
                                Text(
                                  '${item['quantity']}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: () => _updateQuantity(index, 1),
                                  color: Colors.green,
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _removeItem(index),
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Sync Button
              ElevatedButton(
                onPressed: _syncShoppingList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text('Sync with QR Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

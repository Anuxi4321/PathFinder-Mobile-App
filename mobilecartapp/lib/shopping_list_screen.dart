import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<Map<String, dynamic>> _items = [];
  final TextEditingController _itemController = TextEditingController();

  void _addItem() {
    if (_itemController.text.isNotEmpty) {
      setState(() {
        _items.add({'name': _itemController.text, 'quantity': 1});
        _itemController.clear();
      });
    }
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      _items[index]['quantity'] += change;
      if (_items[index]['quantity'] < 1) {
        _items.removeAt(index); // Remove item if quantity is 0
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
      // Navigate to the QR scanner screen and wait for the result
      final result = await Navigator.pushNamed(context, '/qr_scanner');

      // Check if the result contains the MAC address and session key
      if (result != null && result is Map<String, dynamic>) {
        final String macAddress = result['mac'];
        final String sessionKey = result['key'];

        // Encode the shopping list
        final String shoppingListData = jsonEncode({
          'mac': macAddress,
          'key': sessionKey,
          'items': _items,
        });

        // Send the shopping list to the smart cart
        final response = await http.post(
          Uri.parse(
              'http://<SMART_CART_IP>:5000/sync_shopping_list'), // Replace with smart cart IP
          headers: {'Content-Type': 'application/json'},
          body: shoppingListData,
        );

        // Check the response
        if (response.statusCode == 200) {
          // Show success message
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
      // Show error message if sending fails
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        hintText: 'Enter item',
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
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
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
                                _items[index]['name'],
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
                                  '${_items[index]['quantity']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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

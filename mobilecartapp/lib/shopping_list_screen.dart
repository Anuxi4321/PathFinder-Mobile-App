import 'package:flutter/material.dart';
import 'dart:async';
import 'shopping_list_repository.dart';
import 'shopping_list_sync.dart';
import 'shopping_list_widgets.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<Map<String, dynamic>> _items = [];
  final TextEditingController _itemController = TextEditingController();
  final ShoppingListRepository _repository = ShoppingListRepository();
  final ShoppingListSync _sync = ShoppingListSync();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _repository.searchItems(query);
      setState(() {
        _searchResults = results
            .where((item) => item['name'].toLowerCase().startsWith(query.toLowerCase()))
            .toList();
      });
    });
  }

  void _clearSearch() {
    _itemController.clear();
    _onSearchChanged('');
    setState(() {});
  }

  void _addItem(Map<String, dynamic> item) {
    ShoppingListWidgets.showAddItemModal(context, item, () {
      int index = _items.indexWhere((i) => i['name'] == item['name']);
      setState(() {
        if (index != -1) {
          _items[index]['quantity'] += 1;
        } else {
          _items.add({'name': item['name'], 'quantity': 1});
        }
        _clearSearch();
      });
    });
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      _items[index]['quantity'] += change;
      if (_items[index]['quantity'] < 1) {
        _confirmRemoveItem(index);
      }
    });
  }

  void _confirmRemoveItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text('Do you want to remove "${_items[index]['name']}" from the list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _items.removeAt(index);
                });
                Navigator.pop(context); // Close modal
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                TextField(
                  controller: _itemController,
                  onChanged: (query) {
                    _onSearchChanged(query);
                    setState(() {}); // Update UI when typing
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for items',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _itemController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: _clearSearch,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _updateQuantity(index, -1),
                              ),
                              Text('${item['quantity']}'),
                              GestureDetector(
                                onLongPress: () => _updateQuantity(index, 5),
                                child: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _updateQuantity(index, 1),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmRemoveItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _items.isEmpty ? null : () => _sync.syncShoppingList(context, _items),
                  child: const Text('Sync with QR Code'),
                ),
              ],
            ),
            if (_searchResults.isNotEmpty)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: _searchResults.map((item) {
                      return Card(
                        child: ListTile(
                          title: Text(item['name']),
                          onTap: () => _addItem(item),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

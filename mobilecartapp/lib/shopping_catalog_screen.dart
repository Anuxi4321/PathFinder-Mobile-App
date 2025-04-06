import 'package:flutter/material.dart';
import 'db_handler.dart';
import 'shopping_list_store.dart'; // Add this import!

class ShoppingCatalogScreen extends StatefulWidget {
  const ShoppingCatalogScreen({super.key});

  @override
  State<ShoppingCatalogScreen> createState() => _ShoppingCatalogScreenState();
}

class _ShoppingCatalogScreenState extends State<ShoppingCatalogScreen> {
  final DatabaseHandler _dbHandler = DatabaseHandler();
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _dbHandler.getItems();
    setState(() {
      _items = items;
    });
  }

    void _addToShoppingList(Map<String, dynamic> item) {
    final store = ShoppingListStore();

    final alreadyExists = store.items.any((i) => i['name'] == item['name']);
    if (!alreadyExists) {
      store.items.add({
        'name': item['name'],
        'quantity': 1,
        'aisle': item['aisle'] ?? 'N/A',
        'imageUrl': item['imageUrl'] ?? '',
        'price': item['price'] ?? 0.0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['name']} added to list!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['name']} is already in the list')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Catalog')),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 items per row
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(item['imageUrl'], fit: BoxFit.cover),
                ),
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('₱${item['price'].toString()}'),
                ElevatedButton(
                  onPressed: () => _addToShoppingList(item),
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ShoppingListWidgets {
  static void showAddItemModal(BuildContext context, Map<String, dynamic> item, Function onAdd) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${item['name']}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              item['imageUrl'] ?? 'https://via.placeholder.com/100',
              height: 100,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, size: 100),
            ),
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
              onAdd();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ShoppingListWidgets {
  static Future<bool?> showAddItemModal(BuildContext context, Map<String, dynamic> item, Function onAdd) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${item['name']}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              item['imageUrl'] ?? 'assets/images/placeholder.png',
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, size: 100),
            ),
            const SizedBox(height: 10),
            Text('Price: ₱${item['price']?.toStringAsFixed(2) ?? '0.00'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Return false if cancelled
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onAdd();
              Navigator.pop(context, true); // Return true if added
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

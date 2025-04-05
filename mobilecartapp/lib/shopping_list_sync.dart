import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shopping_list_store.dart'; // Import your store

class ShoppingListSync {
  final String smartCartIP = '192.168.1.100'; // Replace with actual cart IP

  Future<void> syncShoppingList(BuildContext context) async {
    final items = ShoppingListStore().items;

    if (items.isEmpty) {
      print('Sync aborted: Shopping list is empty');
      return;
    }

    try {
      final result = await Navigator.pushNamed(
        context,
        '/qr_scanner',
        arguments: items, // Still useful for scanner if needed
      );

      if (result != null && result is Map<String, dynamic>) {
        final String macAddress = result['mac'];
        final String sessionKey = result['key'];

        print('MAC: $macAddress, Key: $sessionKey');
        print('Shopping List before sending: $items');

        final String shoppingListData = jsonEncode({
          'mac': macAddress,
          'key': sessionKey,
          'items': items,
        });

        final Uri url = Uri.parse('http://$smartCartIP:5000/sync_shopping_list');

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: shoppingListData,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shopping list synced successfully!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to sync shopping list'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('Network error: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShoppingListSync {
  Future<void> syncShoppingList(BuildContext context, List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;

    try {
      final result = await Navigator.pushNamed(context, '/qr_scanner');
      if (result != null && result is Map<String, dynamic>) {
        final String macAddress = result['mac'];
        final String sessionKey = result['key'];

        final String shoppingListData = jsonEncode({
          'mac': macAddress,
          'key': sessionKey,
          'items': items,
        });

        final response = await http.post(
          Uri.parse('http://<SMART_CART_IP>:5000/sync_shopping_list'),
          headers: {'Content-Type': 'application/json'},
          body: shoppingListData,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shopping list synced successfully!'), backgroundColor: Colors.green),
          );
        } else {
          throw Exception('Failed to sync shopping list');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sync shopping list. Please try again.'), backgroundColor: Colors.red),
      );
    }
  }
}

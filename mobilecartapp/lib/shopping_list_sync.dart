import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShoppingListSync {
  final String smartCartIP = '192.168.1.100'; // Replace with actual cart IP or make configurable

  Future<void> syncShoppingList(BuildContext context, List<Map<String, dynamic>> items) async {
    if (items.isEmpty) {
      print('Sync aborted: Shopping list is empty');
      return;
    }

    try {
        final result = await Navigator.pushNamed(
          context,
          '/qr_scanner',
          arguments: items, // Pass shopping list here
        );
      if (result != null && result is Map<String, dynamic>) {
        final String macAddress = result['mac'];
        final String sessionKey = result['key'];

        print('MAC: $macAddress, Key: $sessionKey');
        print('Shopping List before sending: $items'); // Debug log

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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShoppingListSync {
  final String smartCartIP = '192.168.1.100'; // Replace with actual cart IP or make configurable

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
          String errorMessage = 'Failed to sync shopping list';
          try {
            if (response.headers['content-type']?.contains('application/json') == true) {
              final responseBody = jsonDecode(response.body);
              if (responseBody is Map<String, dynamic> && responseBody['error'] != null) {
                errorMessage = responseBody['error'];
              }
            }
          } catch (_) {
            errorMessage = 'Unexpected response format';
          }

          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Check connection and try again.'), backgroundColor: Colors.red),
      );
    }
  }
}

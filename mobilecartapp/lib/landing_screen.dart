import 'package:flutter/material.dart';
import 'shopping_list_repository.dart';
import 'shopping_list_store.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _showSavedShoppingLists(BuildContext context) async {
    final repository = ShoppingListRepository();
    final savedLists = await repository.getShoppingLists();

    if (savedLists == null || savedLists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved shopping lists found.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Saved Shopping Lists',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: savedLists.length,
                  itemBuilder: (context, index) {
                    final list = savedLists[index];
                    final itemCount = (list['items'] as List?)?.length ?? 0;
                    return ListTile(
                      title: Text('${list['name'] ?? 'List ${index + 1}'} - ${list['date']}'),
                      subtitle: Text('$itemCount items'),
                      onTap: () => _showListDetails(context, list),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showListDetails(BuildContext context, Map<String, dynamic> list) {
    List<dynamic> items = [];

    try {
      items = list['items'] != null
          ? List<Map<String, dynamic>>.from(
              List<dynamic>.from(list['items'])
                  .map((item) => Map<String, dynamic>.from(item)))
          : [];
    } catch (e) {
      print('Error parsing items: $e');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${list['name'] ?? 'Shopping List'} - ${list['date']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: items.map((item) {
                return ListTile(
                  title: Text('${item['name']}'),
                  subtitle: Text('Quantity: ${item['quantity']}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ShoppingListStore().items.clear();
                ShoppingListStore().items
                    .addAll(items.cast<Map<String, dynamic>>());
                Navigator.pushNamed(context, '/shopping_list');
              },
              child: const Text('Use List'),
            ),
          ],
        );
      },
    );
  }

    @override
    Widget build(BuildContext context) {
      final ButtonStyle commonButtonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        minimumSize: const Size.fromHeight(60), // Ensures same height
        textStyle: const TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
      );

      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'PathFinder',
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Welcome to PathFinder!',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your personal shopping assistant.',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/shopping_list'),
                      icon: const Icon(Icons.list_alt, size: 24),
                      label: const Text('Shopping List'),
                      style: commonButtonStyle,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showSavedShoppingLists(context),
                      icon: const Icon(Icons.shopping_cart, size: 24),
                      label: const Text('View Saved Shopping List'),
                      style: commonButtonStyle,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/qr_scanner'),
                      icon: const Icon(Icons.qr_code_scanner, size: 24),
                      label: const Text('Scan QR Code'),
                      style: commonButtonStyle,
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/catalog'),
                      icon: const Icon(Icons.storefront, size: 24),
                      label: const Text('Browse Catalog'),
                      style: commonButtonStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
}

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'landing_screen.dart';
import 'shopping_list_screen.dart';
import 'qr_scanner_screen.dart';
import 'db_handler.dart';

void main() {
  runApp(const PathfinderApp());
}

class PathfinderApp extends StatelessWidget {
  const PathfinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathfinder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/landing': (context) => const LandingScreen(),
        '/shopping_list': (context) => const ShoppingListScreen(),
        '/qr_scanner': (context) => const QRScannerScreen(),
      },
    );
  }
}

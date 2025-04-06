import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class QRScannerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> shoppingList;

  const QRScannerScreen({super.key, required this.shoppingList});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final TextEditingController _qrCodeController = TextEditingController();
  List<Map<String, dynamic>> shoppingList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final passedData = ModalRoute.of(context)?.settings.arguments;
      if (passedData is List<Map<String, dynamic>>) {
        setState(() {
          shoppingList = passedData;
        });
      }
      print("✅ Shopping List received in QRScannerScreen: $shoppingList");
    });
  }

  /// **📷 Opens the Camera for QR Scanning (Android Only)**
  Future<void> _openCamera() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final intent = AndroidIntent(
          action: 'android.media.action.STILL_IMAGE_CAMERA',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } catch (e) {
        _showError("⚠️ Camera could not be opened. Ensure the app has camera permissions.");
      }
    } else {
      _showError("⚠️ Camera opening is only supported on Android.");
    }
  }

  /// **📡 Processes the scanned QR Code and Syncs Shopping List**
  void _processScan(String data) async {
    print("📤 Sync button pressed");
    print("📎 Raw QR Data: $data");

    if (data.trim().isEmpty) {
      _showError("⚠️ Scanned QR code is empty.");
      return;
    }

    try {
      final Map<String, dynamic> qrData = jsonDecode(data);
      print("✅ Decoded QR JSON: $qrData");

      final String macAddress = qrData['mac'] ?? "";
      final String sessionKey = qrData['key'] ?? "";
      final String smartCartIP = qrData['ip'] ?? "";

      if (macAddress.isEmpty || sessionKey.isEmpty || smartCartIP.isEmpty) {
        throw Exception('⚠️ Invalid QR data: Missing MAC address, session key, or IP');
      }

      print("🔹 MAC: $macAddress, Key: $sessionKey, IP: $smartCartIP");

      if (shoppingList.isEmpty) {
        print("❌ Shopping list is empty! Cannot sync.");
        _showError("⚠️ Shopping list is empty. Add items before syncing.");
        return;
      }

      print("✅ Shopping List before sync: $shoppingList");

      final Map<String, dynamic> payload = {
        "mac": macAddress,
        "items": shoppingList,
      };

      final String syncUrl = "http://$smartCartIP:5000/sync_shopping_list";

      print("📤 Sending JSON payload: ${jsonEncode(payload)}");

      final response = await http.post(
        Uri.parse(syncUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(payload),
      );

      print("📩 Response Status: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        _showSuccess("✅ Shopping list synced successfully!");
        Navigator.pop(context, {'mac': macAddress, 'key': sessionKey, 'shopping_list': shoppingList});
      } else {
        throw Exception("❌ Failed to sync shopping list: ${response.body}");
      }
    } catch (e) {
      print("🚨 Error: $e");
      _showError('🚨 Error: ${e.toString()}');
    }
  }

  /// **🚨 Displays an error message**
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// **✅ Displays a success message**
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("📜 Received Shopping List in UI: $shoppingList");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync the QR Code'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _qrCodeController,
              decoration: const InputDecoration(
                labelText: "Paste QR Code Data Here",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _buildButton('📷 Open Camera', _openCamera, Colors.blueAccent),
            _buildButton('🔄 Sync Shopping List', () => _processScan(_qrCodeController.text), Colors.green),
            _buildButton('⬅️ Back to Shopping List', () => Navigator.pop(context), Colors.grey[300]!, textColor: Colors.black),
          ],
        ),
      ),
    );
  }

 Widget _buildButton(String label, VoidCallback onPressed, Color color, {Color textColor = Colors.white}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: SizedBox(
      width: double.infinity, // Full width button
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: TextStyle(fontSize: 18, color: textColor)),
      ),
    ),
  );
}
}
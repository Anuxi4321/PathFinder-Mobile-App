import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class QRScannerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> shoppingList; // ✅ Accept shopping list

  const QRScannerScreen({super.key, required this.shoppingList}); // ✅ Constructor

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = false;
  bool _isProcessing = false; // ✅ Prevent duplicate scans
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _qrViewController;
  final String smartCartIP = "192.168.1.100"; // ✅ Configurable IP

  Future<void> _toggleScanner() async {
    var status = await Permission.camera.request();

    if (status.isGranted) {
      setState(() => _isScanning = !_isScanning);
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission denied. Please allow access.'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Camera permission permanently denied. Open settings to enable.',
          ),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrViewController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing) {
        _isProcessing = true; // ✅ Prevent multiple scans
        setState(() => _isScanning = false);
        _processScan(scanData.code!);
      }
    });
  }

  void _processScan(String data) async {
    try {
      final Map<String, dynamic> qrData = jsonDecode(data);
      final String macAddress = qrData['mac'] ?? "";
      final String sessionKey = qrData['key'] ?? "";

      if (macAddress.isEmpty || sessionKey.isEmpty) {
        throw Exception('Invalid QR data');
      }

      // ✅ Use the shopping list passed from ShoppingListScreen
      List<Map<String, dynamic>> shoppingList = widget.shoppingList;

      final String cartUrl = "http://$smartCartIP:5000/sync_shopping_list";

      final Map<String, dynamic> requestBody = {
        "mac": macAddress,
        "key": sessionKey, // ✅ Include sessionKey
        "shopping_list": shoppingList,
      };

      final response = await http.post(
        Uri.parse(cartUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, {'mac': macAddress, 'key': sessionKey});
      } else {
        throw Exception("Failed to sync shopping list: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isProcessing = false; // ✅ Allow scanning again
    }
  }

  @override
  void dispose() {
    _qrViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync the QR Code'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: _isScanning
                ? QRView(
                    key: _qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.blueAccent,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 300,
                    ),
                  )
                : _buildScannerPlaceholder(),
          ),
          _buildButton('Sync the QR Code', _toggleScanner, Colors.blueAccent,
              _isScanning ? 'Stop Scanning' : 'Sync the QR Code'),
          _buildButton('Back to Shopping List', () => Navigator.pop(context),
              Colors.grey[300]!, 'Back to Shopping List',
              textColor: Colors.black),
        ],
      ),
    );
  }

  Widget _buildScannerPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 20),
          const Text(
            'Press "Sync the QR Code" to start scanning',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
      String label, VoidCallback onPressed, Color color, String buttonText,
      {Color textColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          buttonText,
          style: TextStyle(fontSize: 18, color: textColor),
        ),
      ),
    );
  }
}

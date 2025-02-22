import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert'; // For JSON decoding

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = false;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _qrViewController;

  // Request camera permission before enabling the scanner
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
              openAppSettings(); // Open app settings to enable camera
            },
          ),
        ),
      );
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrViewController = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() => _isScanning = false);
      _processScan(scanData.code!);
    });
  }

  void _processScan(String data) {
    try {
      // Parse the QR data (expected format: {"mac": "XX:XX:XX:XX:XX:XX", "key": "sessionKey"})
      final Map<String, dynamic> qrData = jsonDecode(data);
      final String macAddress = qrData['mac'];
      final String sessionKey = qrData['key'];

      // Validate the data
      if (macAddress.isEmpty || sessionKey.isEmpty) {
        throw Exception('Invalid QR data');
      }

      // Navigate back to the shopping list with the scanned data
      Navigator.pop(context, {'mac': macAddress, 'key': sessionKey});
    } catch (e) {
      // Show error message if QR data is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR code. Please scan a valid sync code.'),
          backgroundColor: Colors.red,
        ),
      );
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

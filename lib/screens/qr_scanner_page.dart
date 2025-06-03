import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  final Function(String) onUserIdScanned;
  const QrScannerPage({super.key, required this.onUserIdScanned});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Friend's QR")),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          if (!_scanned) {
            final List<Barcode> barcodes = barcodeCapture.barcodes;
            if (barcodes.isNotEmpty) {
              final barcode = barcodes.first;
              if (barcode.rawValue != null) {
                _scanned = true;
                final userId = barcode.rawValue!;
                widget.onUserIdScanned(userId);
                Navigator.pop(context);
              }
            }
          }
        },
      ),
    );
  }
}

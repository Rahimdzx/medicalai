import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ==========================================
// 1. شاشة المسح (Scanner) - عامة وقابلة لإعادة الاستخدام
// ==========================================
class GeneralQRScanner extends StatefulWidget {
  final String title;
  const GeneralQRScanner({super.key, this.title = "Scan QR Code"});

  @override
  State<GeneralQRScanner> createState() => _GeneralQRScannerState();
}

class _GeneralQRScannerState extends State<GeneralQRScanner> {
  bool _isScanned = false; // لمنع التكرار السريع

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_isScanned) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _isScanned = true);
                  // إرجاع القيمة للشاشة السابقة لمعالجتها
                  Navigator.pop(context, barcode.rawValue); 
                  break;
                }
              }
            },
          ),
          // إطار توضيحي للمسح (Overlay)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 4),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 1000, // تعتيم الخلفية حول المربع
                  )
                ],
              ),
            ),
          ),
          // نص توضيحي
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              "وجه الكاميرا نحو رمز QR",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. شاشة العرض (Generator) - عامة
// ==========================================
class QRDisplayScreen extends StatelessWidget {
  final String data;
  final String title;
  final String description;

  const QRDisplayScreen({
    super.key, 
    required this.data, 
    this.title = "My QR Code",
    this.description = "Share this code",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                description,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 10)
                  ],
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Data: $data", // اختياري: لعرض النص تحت الكود
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

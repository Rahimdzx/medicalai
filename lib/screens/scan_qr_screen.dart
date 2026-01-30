import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRScreen extends StatelessWidget {
  const ScanQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مسح رمز الطبيب")),
      body: MobileScanner(
        // هذه الدالة تعمل فور العثور على أي رمز QR
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? doctorId = barcode.rawValue;
            if (doctorId != null) {
              // إغلاق شاشة الكاميرا والرجوع بالمعرف الممسوح
              Navigator.pop(context, doctorId);
              
              // يمكنك هنا التوجيه مباشرة لصفحة الطبيب الممسوح
              print("تم التعرف على الطبيب: $doctorId");
            }
          }
        },
      ),
    );
  }
}

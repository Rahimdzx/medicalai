import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/app_localizations.dart';
import 'doctor_booking_screen.dart'; // تأكد من استيراد صفحة الحجز

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // التحكم في الكاميرا (الفلاش، التبديل بين الكاميرات)
  final MobileScannerController controller = MobileScannerController();
  
  bool isScanned = false;
  String? scannedData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanQR),
        actions: [
          // زر التحكم في فلاش الكاميرا
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          // زر التبديل بين الكاميرا الأمامية والخلفية
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // الجزء العلوي: منطقة المسح (الكاميرا)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    if (isScanned) return;

                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String? doctorId = barcodes.first.rawValue;
                      if (doctorId != null) {
                        setState(() {
                          isScanned = true;
                          scannedData = doctorId;
                        });

                        // الانتقال التلقائي لصفحة الطبيب بعد نجاح المسح
                        _navigateToDoctor(doctorId);
                      }
                    }
                  },
                ),
                // إضافة إطار بصري (Overlay) ليعرف المستخدم أين يضع الكود
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // الجزء السفلي: عرض الحالة والنتائج
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isScanned) ...[
                    const Icon(Icons.qr_code_scanner, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(l10n.pointCameraToQR, style: const TextStyle(fontSize: 16)),
                  ] else ...[
                    const Icon(Icons.check_circle, size: 48, color: Colors.green),
                    const SizedBox(height: 8),
                    Text(
                      l10n.scannedSuccessfully,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "ID: ${scannedData ?? ''}",
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // زر للمسح مرة أخرى في حال حدوث خطأ
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          isScanned = false;
                          scannedData = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.scanAgain),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة الانتقال لصفحة الحجز
  void _navigateToDoctor(String doctorId) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorBookingScreen(doctorId: doctorId),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose(); // إغلاق الكاميرا عند الخروج من الصفحة لتوفير البطارية
    super.dispose();
  }
}

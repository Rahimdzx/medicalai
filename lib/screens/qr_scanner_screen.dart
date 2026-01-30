import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../l10n/app_localizations.dart';
import 'doctor_booking_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // استخدام المتحكم الافتراضي
  final MobileScannerController controller = MobileScannerController();
  bool isScanned = false;
  String? scannedData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pointCameraToQR), // تأكد من وجود هذا المفتاح في l10n
        actions: [
          // التحكم في الفلاش
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              final torchState = state.torchState;
              return IconButton(
                icon: Icon(
                  torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: torchState == TorchState.on ? Colors.yellow : Colors.grey,
                ),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          // تبديل الكاميرا
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
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
                        _navigateToDoctor(doctorId);
                      }
                    }
                  },
                ),
                // إطار التركيز
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
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
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
    controller.dispose();
    super.dispose();
  }
}

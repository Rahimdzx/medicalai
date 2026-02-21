import 'package:flutter/material.dart';
import 'common/qr_share_scan_screen.dart';

/// General QR Scanner wrapper
/// Used by PatientDashboard for scanning doctor QR codes
class GeneralQRScanner extends StatelessWidget {
  final String title;

  const GeneralQRScanner({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue[800],
      ),
      body: const QrShareScanScreen(),
    );
  }
}

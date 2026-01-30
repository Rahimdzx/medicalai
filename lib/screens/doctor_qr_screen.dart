import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DoctorQRScreen extends StatelessWidget {
  const DoctorQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final String doctorId = auth.user?.uid ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text("Doctor QR Code")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Share this with your patient", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            QrImageView(
              data: doctorId,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

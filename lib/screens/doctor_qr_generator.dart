import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DoctorQRGenerator extends StatelessWidget {
  const DoctorQRGenerator({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // نستخدم الـ UID الخاص بالطبيب كبيانات داخل الـ QR
    final String doctorData = authProvider.user?.uid ?? "unknown";

    return Scaffold(
      appBar: AppBar(title: const Text("Clinic QR Code")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Share this code with patients to book", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade100, width: 2)
              ),
              child: QrImageView(
                data: doctorData,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
            const SizedBox(height: 20),
            Text("Dr. ${authProvider.user?.email?.split('@')[0]}", 
              style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

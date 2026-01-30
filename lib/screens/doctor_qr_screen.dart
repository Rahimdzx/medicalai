import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DoctorQRScreen extends StatelessWidget {
  const DoctorQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على بيانات الطبيب المسجل حالياً
    final auth = Provider.of<AuthProvider>(context);
    final String doctorId = auth.user?.uid ?? "unknown";

    return Scaffold(
      appBar: AppBar(title: const Text("رمز الـ QR الخاص بي")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "اطلب من المريض مسح هذا الرمز",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // الكود الذي يولد الصورة بناءً على ID الطبيب
            QrImageView(
              data: doctorId,
              version: QrVersions.auto,
              size: 250.0,
              gapless: false,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 20),
            Text("معرف الطبيب: $doctorId", 
                 style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

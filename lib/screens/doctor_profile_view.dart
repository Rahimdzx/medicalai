import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class DoctorProfileView extends StatelessWidget {
  final String doctorId;

  const DoctorProfileView({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordDetails),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(doctorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text(l10n.userNotFound));
          }

          var doctorData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // الصورة الشخصية مع معالجة الرابط الفارغ
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: (doctorData['photoUrl'] != null && doctorData['photoUrl'].toString().isNotEmpty)
                      ? NetworkImage(doctorData['photoUrl'])
                      : null,
                  child: (doctorData['photoUrl'] == null || doctorData['photoUrl'].toString().isEmpty)
                      ? const Icon(Icons.person, size: 70, color: Colors.blue)
                      : null,
                ),
                const SizedBox(height: 20),

                Text(
                  "Dr. ${doctorData['name'] ?? ''}",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text(
                  doctorData['specialization'] ?? l10n.doctor,
                  style: TextStyle(fontSize: 18, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),

                Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _infoTile(Icons.payments_outlined, "Consultation Fee / Цена / السعر", "${doctorData['price'] ?? '50'} USD"),
                        const Divider(height: 30),
                        _infoTile(Icons.event_available_outlined, "Schedule / График / المواعيد", doctorData['schedule'] ?? "Mon-Fri / Пн-Пт"),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleBooking(context, doctorData),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Book Now / Записаться / احجز الآن",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade600),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleBooking(BuildContext context, Map<String, dynamic> doctorData) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Login / Войдите / يرجى تسجيل الدخول")),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // إرسال البيانات لمجموعتك الجديدة 'appointments'
      await FirebaseFirestore.instance.collection('appointments').add({
        'doctorId': doctorId,
        'doctorName': doctorData['name'],
        'patientId': authProvider.user!.uid,
        'patientName': authProvider.user!.email?.split('@')[0] ?? "Patient",
        'status': 'pending',
        'price': doctorData['price'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context); // إغلاق التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking Sent! / Запись отправлена! / تم إرسال الطلب!"), 
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

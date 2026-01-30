import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorBookingScreen extends StatelessWidget {
  final String doctorId;
  const DoctorBookingScreen({super.key, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(doctorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Doctor not found"));
          }

          var doctorData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text("Dr. ${doctorData['name'] ?? 'Consultant'}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  subtitle: Text(doctorData['specialization'] ?? "Specialist"),
                ),
                const Divider(),
                const SizedBox(height: 10),
                // عرض السعر
                _buildInfoTile(Icons.payments_outlined, "Consultation Fee", "${doctorData['price'] ?? '50'} USD"),
                const SizedBox(height: 10),
                // عرض المواعيد (Weekly Schedule)
                const Text("Available Slots this week:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Text(doctorData['schedule'] ?? "Mon-Fri: 09:00 AM - 05:00 PM"),
                
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // هنا نتحقق من تسجيل الدخول قبل الدفع والحجز
                      _handleBooking(context);
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: const Text("Book and Pay Now"),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 10),
        Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _handleBooking(BuildContext context) {
    // منطق التحقق من التسجيل: إذا لم يكن مسجلاً، وجهه لصفحة Login
    Navigator.pushNamed(context, '/login');
  }
}

import 'package:flutter/material.dart';
import '../screens/doctor_booking_screen.dart';

class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctorData;
  final String doctorId;

  const DoctorCard({super.key, required this.doctorData, required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () {
          // الانتقال لشاشة الحجز عند الضغط
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DoctorBookingScreen(doctorId: doctorId)),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(doctorData['photoUrl'] ?? 'https://via.placeholder.com/150'),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctorData['name'] ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(doctorData['specialization'] ?? '', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text("\$ ${doctorData['price']}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

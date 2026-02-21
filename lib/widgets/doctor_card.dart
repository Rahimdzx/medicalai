import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../screens/doctor_profile_screen.dart';

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorProfileScreen(
                doctor: DoctorModel(
                  id: doctorId,
                  userId: doctorData['userId'] ?? doctorId,
                  name: doctorData['name'] ?? 'Doctor',
                  nameEn: doctorData['nameEn'] ?? doctorData['name'] ?? 'Doctor',
                  nameAr: doctorData['nameAr'] ?? doctorData['name'] ?? 'Doctor',
                  specialty: doctorData['specialty'] ?? 'General',
                  specialtyEn: doctorData['specialtyEn'] ?? doctorData['specialty'] ?? 'General',
                  specialtyAr: doctorData['specialtyAr'] ?? doctorData['specialty'] ?? 'عام',
                  price: (doctorData['price'] ?? 0).toDouble(),
                  currency: doctorData['currency'] ?? 'RUB',
                  rating: (doctorData['rating'] ?? 5.0).toDouble(),
                  doctorNumber: doctorData['doctorNumber'] ?? doctorId.substring(0, 8).toUpperCase(),
                  description: doctorData['description'] ?? '',
                  isActive: doctorData['isActive'] ?? true,
                  allowedFileTypes: List<String>.from(doctorData['allowedFileTypes'] ?? ['image', 'pdf']),
                  createdAt: DateTime.now(),
                  photo: doctorData['photo'],
                ),
              ),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(doctorData['photo'] ?? 'https://via.placeholder.com/150'),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctorData['name'] ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(doctorData['specialty'] ?? '', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text("${doctorData['price']} ${doctorData['currency'] ?? 'RUB'}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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

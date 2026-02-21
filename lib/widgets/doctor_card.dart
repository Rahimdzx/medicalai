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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to doctor profile
          final doctor = DoctorModel(
            id: doctorId,
            userId: doctorData['userId'] ?? doctorId,
            name: doctorData['name'] ?? 'Doctor',
            nameEn: doctorData['nameEn'] ?? doctorData['name'] ?? 'Doctor',
            nameAr: doctorData['nameAr'] ?? doctorData['name'] ?? 'Doctor',
            specialty: doctorData['specialization'] ?? 'General',
            specialtyEn: doctorData['specializationEn'] ?? doctorData['specialization'] ?? 'General',
            specialtyAr: doctorData['specializationAr'] ?? doctorData['specialization'] ?? 'General',
            price: (doctorData['price'] ?? 0).toDouble(),
            currency: doctorData['currency'] ?? 'USD',
            rating: (doctorData['rating'] ?? 0).toDouble(),
            doctorNumber: doctorData['doctorNumber'] ?? '',
            description: doctorData['description'] ?? '',
            isActive: doctorData['isActive'] ?? true,
            allowedFileTypes: List<String>.from(doctorData['allowedFileTypes'] ?? ['image', 'pdf']),
            createdAt: doctorData['createdAt']?.toDate() ?? DateTime.now(),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DoctorProfileScreen(doctor: doctor)),
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

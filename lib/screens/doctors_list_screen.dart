import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// اضعها هنا في الأعلى مع باقي الاستيرادات 
import '../widgets/doctor_card.dart'; 

class DoctorsListScreen extends StatelessWidget {
  final String specialty;

  const DoctorsListScreen({super.key, required this.specialty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("أطباء $specialty")),
      body: StreamBuilder<QuerySnapshot>(
        // جلب الأطباء من Firestore بناءً على التخصص
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .where('specialization', isEqualTo: specialty)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا يوجد أطباء في هذا التخصص حالياً"));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              // استخراج البيانات من Firestore وتحويلها إلى Map
              final doctorData = doctors[index].data() as Map<String, dynamic>;
              
              // هنا نستخدم الـ DoctorCard التي استوردناها من مجلد widgets
              return DoctorCard(doctorData: doctorData);
            },
          );
        },
      ),
    );
  }
}

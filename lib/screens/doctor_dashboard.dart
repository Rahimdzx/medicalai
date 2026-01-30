import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import 'doctor_qr_screen.dart'; // ستحتاج لإنشاء هذا الملف

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        actions: [
          // زر عرض الـ QR الخاص بالطبيب
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorQRScreen()),
            ),
          ),
          IconButton(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('records')
            .where('doctorId', isEqualTo: auth.user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No records added yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final record = PatientRecord.fromFirestore(snapshot.data!.docs[index]);
              return _RecordCard(record: record);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // كود إضافة سجل جديد لمريض
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final PatientRecord record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text("Patient: ${record.patientEmail}"),
        subtitle: Text("Date: ${record.date}"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

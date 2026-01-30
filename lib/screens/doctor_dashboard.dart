import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        actions: [
          IconButton(onPressed: () => auth.signOut(), icon: const Icon(Icons.logout))
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
              // هنا تم تعريف _RecordCard بالأسفل لحل الخطأ
              return _RecordCard(record: record);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // كود إضافة سجل جديد هنا
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// الكود المفقود الذي كان يسبب الخطأ في الـ Build
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
        onTap: () {
          // كود عرض التفاصيل
        },
      ),
    );
  }
}

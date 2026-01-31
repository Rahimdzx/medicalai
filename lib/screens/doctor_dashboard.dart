import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import 'doctor_qr_screen.dart';
import 'chat_screen.dart'; // إضافة المحادثة هنا أيضاً
import 'video_call_screen.dart';

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة تحكم الطبيب"),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorQRScreen())),
          ),
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
            return const Center(child: Text("لا توجد سجلات مضافة بعد"));
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
          // هنا يمكنك إضافة شاشة "إضافة تشخيص جديد لمريض"
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_search)),
        title: Text("المريض: ${record.patientEmail}"),
        subtitle: Text("التاريخ: ${record.date}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر المحادثة للطبيب للتواصل مع المريض
            IconButton(
              icon: const Icon(Icons.message, color: Colors.blue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(appointmentId: record.doctorId, receiverName: record.patientEmail),
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // يمكن هنا فتح تفاصيل السجل كاملة
        },
      ),
    );
  }
}

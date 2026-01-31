import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/patient_record.dart';
import 'doctor_qr_screen.dart';
import 'chat_screen.dart'; 
import 'video_call_screen.dart';
// استورد شاشة الملف الشخصي إذا قمت بإنشائها
// import 'doctor_profile_screen.dart'; 

class DoctorDashboard extends StatelessWidget {
  const DoctorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب بيانات المزود للوصول لبيانات الطبيب الحالي
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة تحكم الطبيب"),
        actions: [
          // الأيقونة التي أشرت إليها في الصورة - أيقونة الملف الشخصي
          IconButton(
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: (auth.photoUrl != null && auth.photoUrl!.isNotEmpty)
                  ? NetworkImage(auth.photoUrl!)
                  : null,
              child: (auth.photoUrl == null || auth.photoUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: Colors.blue)
                  : null,
            ),
            onPressed: () {
              // عند الضغط يفتح ملف الطبيب أو يعرض معلوماته
              _showDoctorInfo(context, auth);
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const DoctorQRScreen())
            ),
          ),
          IconButton(
            onPressed: () => auth.signOut(), // تسجيل الخروج
            icon: const Icon(Icons.logout, color: Colors.red),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب السجلات الخاصة بهذا الطبيب فقط
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // هنا يتم ربط شاشة إضافة سجل جديد
          // Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecordScreen()));
        },
        label: const Text("سجل جديد"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // دالة بسيطة لعرض معلومات الطبيب عند الضغط على أيقونة الشخص
  void _showDoctorInfo(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: (auth.photoUrl != null && auth.photoUrl!.isNotEmpty)
                  ? NetworkImage(auth.photoUrl!)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(auth.userName ?? "اسم الطبيب", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(auth.user?.email ?? ""),
            const SizedBox(height: 10),
            Text("سعر الكشف: ${auth.price} \$", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
          ],
        ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          "المريض: ${record.patientEmail}", // عرض بريد المريض
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("التاريخ: ${record.date}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر المحادثة
            IconButton(
              icon: const Icon(Icons.message, color: Colors.blue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    appointmentId: record.doctorId, 
                    receiverName: record.patientEmail
                  ),
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // فتح تفاصيل السجل
        },
      ),
    );
  }
}

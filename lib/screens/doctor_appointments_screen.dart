import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'video_call_screen.dart'; // تأكد من استيراد شاشة الاتصال

class DoctorAppointmentsScreen extends StatelessWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorId = Provider.of<AuthProvider>(context).user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text("Appointments / Записи", style: TextStyle(fontSize: 18)),
            Text("المواعيد المستلمة", style: TextStyle(fontSize: 14)),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No appointments yet\nЗаписей пока нет\nلا توجد مواعيد حالياً",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              var appointment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              var docId = snapshot.data!.docs[index].id; // هذا هو الـ Channel Name

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(appointment['status']).withOpacity(0.2),
                    child: Icon(Icons.person, color: _getStatusColor(appointment['status'])),
                  ),
                  title: Text(
                    appointment['patientName'] ?? 'Unknown Patient',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("Status: ${appointment['status']}"),
                      Text("Price: ${appointment['price'] ?? '50'} USD"),
                    ],
                  ),
                  // التعديل هنا: إضافة زر الاتصال بجانب زر التأكيد
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // يظهر زر الاتصال فقط إذا كان الموعد مؤكداً
                      if (appointment['status'] == 'confirmed')
                        IconButton(
                          icon: const Icon(Icons.videocam, color: Colors.blue, size: 30),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoCallScreen(
                                  channelName: docId, // نرسل الـ ID كإسم للغرفة
                                  token: "", // فارغ لوضع الاختبار
                                ),
                              ),
                            );
                          },
                        ),
                      
                      // زر التأكيد (يختفي إذا تم التأكيد مسبقاً)
                      if (appointment['status'] == 'pending')
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                          onPressed: () => _confirmAppointment(context, docId),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'pending') return Colors.orange;
    if (status == 'confirmed') return Colors.green;
    return Colors.grey;
  }

  Future<void> _confirmAppointment(BuildContext context, String id) async {
    await FirebaseFirestore.instance.collection('appointments').doc(id).update({
      'status': 'confirmed'
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Confirmed / Подтверждено / تم التأكيد")),
      );
    }
  }
}
